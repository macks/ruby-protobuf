require 'stringio'
require 'protobuf/descriptor/descriptor'
require 'protobuf/message/decoder'
require 'protobuf/message/encoder'
require 'protobuf/message/field'
require 'protobuf/message/protoable'

module Protobuf
  OPTIONS = {}

  class Message

    class <<self
      include Protoable

      # Reserve field numbers for extensions. Don't use this method directly.
      def extensions(range)
        @extension_tag = range
      end

      # Define a required field. Don't use this method directly.
      def required(type, name, tag, options={})
        define_field(:required, type, name, tag, options)
      end

      # Define a optional field. Don't use this method directly.
      def optional(type, name, tag, options={})
        define_field(:optional, type, name, tag, options)
      end

      # Define a repeated field. Don't use this method directly.
      def repeated(type, name, tag, options={})
        define_field(:repeated, type, name, tag, options)
      end

      # Define a field. Don't use this method directly.
      def define_field(rule, type, fname, tag, options)
        if options[:extension] && ! extension_tag?(tag)
          raise RangeError, "#{tag} is not in #{@extension_tag}"
        end

        if fields.include?(tag)
          raise TagCollisionError, "Field tag #{tag} has already been used in #{self.name}."
        end
        fields[tag] = Field.build(self, rule, type, fname, tag, options)
        clear_field_cache
      end

      def extension_tag?(tag)
        @extension_tag.include?(tag)
      end

      # A collection of field object.
      def fields
        @fields ||= {}
      end

      # A collection of field object, which is sorted by tag number.
      def sorted_fields
        @sorted_fields ||= fields.sort_by {|tag, _| tag}
      end
      private :sorted_fields

      #:nodoc:
      def field_dictionary
        return @field_dictionary if @field_dictionary
        @field_dictionary = fields.dup
        fields.each do |_, field|
          @field_dictionary[field.name] = field
          @field_dictionary[field.name.to_s] = field
        end
        @field_dictionary
      end
      private :field_dictionary

      #:nodoc:
      def clear_field_cache
        @field_dictionary = nil
        @sorted_fields = nil
      end
      private :clear_field_cache

      # Find a field object by +tag_or_name+.
      def get_field(tag_or_name)
        case tag_or_name
        when Integer, String, Symbol
          field_dictionary[tag_or_name]
        else
          raise TypeError, tag_or_name.class
        end
      end

      alias get_field_by_tag  get_field  # for compatibility
      alias get_field_by_name get_field  # for compatibility

      def descriptor
        @descriptor ||= Descriptor::Descriptor.new(self)
      end
    end

    def initialize(values={})
      @values = {}

      self.class.fields.dup.each do |tag, field|
        unless field.ready?
          field = field.setup
          self.class.fields[tag] = field
          self.class.__send__(:clear_field_cache)
        end
        if field.repeated?
          @values[field.name] = Field::FieldArray.new(field)
        end
      end

      values.each {|name, val| self.__send__("#{name}=", val)}
    end

    def initialized?
      fields.all? {|tag, field| field.initialized?(self) }
    end

    def has_field?(tag_or_name)
      field = get_field(tag_or_name)
      raise ArgumentError, "unknown field: #{tag_or_name.inspect}" unless field
      @values.has_key?(field.name)
    end

    def ==(obj)
      return false unless obj.is_a?(self.class)
      each_field do |field, value|
        return false unless value == obj.__send__(field.name)
      end
      true
    end

    def clear!
      @values.delete_if do |_, value|
        if value.is_a?(Field::FieldArray)
          value.clear
          false
        else
          true
        end
      end
      self
    end

    def dup
      copy_to(super, :dup)
    end

    def clone
      copy_to(super, :clone)
    end

    def copy_to(object, method)
      duplicate = proc {|obj|
        case obj
        when Message, String then obj.__send__(method)
        else                      obj
        end
      }

      object.__send__(:initialize)
      @values.each do |name, value|
        if value.is_a?(Field::FieldArray)
          object.__send__(name).replace(value.map {|v| duplicate.call(v)})
        else
          object.__send__("#{name}=", duplicate.call(value))
        end
      end
      object
    end
    private :copy_to

    def inspect(indent=0)
      result = []
      i = '  ' * indent
      field_value_to_string = lambda {|field, value|
        result << \
          if field.optional? && ! @values.has_key?(field.name)
            ''
          else
            case field
            when Field::MessageField
              if value.nil?
                "#{i}#{field.name} {}\n"
              else
                "#{i}#{field.name} {\n#{value.inspect(indent + 1)}#{i}}\n"
              end
            when Field::EnumField
              if value.is_a?(EnumValue)
                "#{i}#{field.name}: #{value.name}\n"
              else
                "#{i}#{field.name}: #{field.type.name_by_value(value)}\n"
              end
            else
              "#{i}#{field.name}: #{value.inspect}\n"
            end
          end
      }
      each_field do |field, value|
        if field.repeated?
          value.each do |v|
            field_value_to_string.call(field, v)
          end
        else
          field_value_to_string.call(field, value)
        end
      end
      result.join
    end

    def parse_from_string(string)
      parse_from(StringIO.new(string))
    end

    def parse_from_file(filename)
      if filename.is_a?(File)
        parse_from(filename)
      else
        File.open(filename, 'rb') do |f|
          parse_from(f)
        end
      end
    end

    def parse_from(stream)
      Decoder.decode(stream, self)
    end

    def serialize_to_string(string='')
      io = StringIO.new(string)
      serialize_to(io)
      result = io.string
      result.force_encoding(Encoding::BINARY) if result.respond_to?(:force_encoding)
      result
    end
    alias to_s serialize_to_string

    def serialize_to_file(filename)
      if filename.is_a?(File)
        serialize_to(filename)
      else
        File.open(filename, 'wb') do |f|
          serialize_to(f)
        end
      end
    end

    def serialize_to(stream)
      Encoder.encode(stream, self)
    end

    def merge_from(message)
      fields.each {|tag, field| field.merge(self, message.__send__(field.name))}
    end

    def [](tag_or_name)
      if field = get_field(tag_or_name)
        __send__(field.name)
      else
        raise NoMethodError, "No such field: #{tag_or_name.inspect}"
      end
    end

    def []=(tag_or_name, value)
      if field = get_field(tag_or_name)
        __send__("#{field.name}=", value)
      else
        raise NoMethodError, "No such field: #{tag_or_name.inspect}"
      end
    end

    # Returns a hash; which key is a tag number, and value is a field object.
    def fields
      self.class.fields
    end

    # Returns field object or +nil+.
    def get_field_by_name(name)
      self.class.get_field_by_name(name)
    end

    # Returns field object or +nil+.
    def get_field_by_tag(tag)
      self.class.get_field_by_tag(tag)
    end

    # Returns field object or +nil+.
    def get_field(tag_or_name)
      self.class.get_field(tag_or_name)
    end

    # Iterate over a field collection.
    #   message.each_field do |field_object, value|
    #     # do something
    #   end
    def each_field
      self.class.__send__(:sorted_fields).each do |_, field|
        value = __send__(field.name)
        yield(field, value)
      end
    end

    def to_hash
      hash = {}
      each_field do |field, value|
        next unless @values.has_key?(field.name)
        case value
        when Array
          next if value.empty?
          hash[field.name] = value.map {|val| val.is_a?(Message) ? val.to_hash : val}
        when Message
          hash[field.name] = value.to_hash
        when EnumValue
          hash[field.name] = value.name
        else
          hash[field.name] = value
        end
      end
      hash
    end

  end
end
