require 'pp'
require 'stringio'
require 'protobuf/descriptor/descriptor'
require 'protobuf/message/decoder'
require 'protobuf/message/encoder'
require 'protobuf/message/field'
require 'protobuf/message/protoable'

module Protobuf
  OPTIONS = {}

  class Message
    class TagCollisionError < StandardError; end

    class ExtensionFields < Hash
      def initialize(key_range=0..-1)
        @key_range = key_range
      end

      def []=(key, value)
        raise RangeError.new("#{key} is not in #{@key_range}") unless @key_range.include? key
        super
      end

      def include_tag?(tag)
        @key_range.include? tag
      end
    end

    class <<self
      include Protobuf::Protoable
      def fields; @fields ||= {} end

      def extensions(range)
        @extension_fields = ExtensionFields.new range
      end

      def required(type, name, tag, opts={})
        define_field :required, type, name, tag, opts
      end

      def optional(type, name, tag, opts={})
        define_field :optional, type, name, tag, opts
      end

      def repeated(type, name, tag, opts={})
        define_field :repeated, type, name, tag, opts
      end

      def define_field(rule, type, fname, tag, opts={})
        field_hash = opts[:extension] ? extension_fields : (@fields ||= {})
        raise Protobuf::Message::TagCollisionError.new(<<-eos.strip) if field_hash.keys.include? tag
          Field number #{tag} has already been used in "#{self.name}" by field "#{fname}".
        eos
        field_hash[tag] = Protobuf::Field.build self, rule, type, fname, tag, opts
      end

      def extension_tag?(tag)
        extension_fields.include_tag? tag
      end

      def extension_fields
        @extension_fields ||= ExtensionFields.new
      end

      def get_field_by_name(name)
        name = name.to_sym
        fields.values.find {|field| field.name == name}
      end

      def get_field_by_tag(tag)
        fields[tag]
      end

      def get_field(tag_or_name)
        case tag_or_name
        when Integer; get_field_by_tag tag_or_name
        when String, Symbol; get_field_by_name tag_or_name
        else; raise TypeError.new(tag_or_name.class)
        end
      end

      #TODO merge to get_field_by_name
      def get_ext_field_by_name(name)
        name = name.to_sym
        extension_fields.values.find {|field| field.name == name}
      end

      #TODO merge to get_field_by_tag
      def get_ext_field_by_tag(tag)
        extension_fields[tag]
      end

      #TODO merge to get_field
      def get_ext_field(tag_or_name)
        case tag_or_name
        when Integer; get_ext_field_by_tag tag_or_name
        when String, Symbol; get_ext_field_by_name tag_or_name
        else; raise TypeError.new(tag_or_name.class)
        end
      end

      def descriptor
        @descriptor ||= Protobuf::Descriptor::Descriptor.new(self)
      end
    end

    def initialize(values={})
      @values = {}

      self.class.fields.each do |tag, field|
        unless field.ready?
          field = field.setup
          self.class.class_eval {@fields[tag] = field}
        end
        if field.repeated?
          @values[field.name] = Protobuf::Field::FieldArray.new(field)
        end
      end

      # TODO
      self.class.extension_fields.each do |tag, field|
        unless field.ready?
          field = field.setup
          self.class.class_eval {@extension_fields[tag] = field}
        end
        if field.repeated?
          @values[field.name] = Protobuf::Field::FieldArray.new(field)
        end
      end

      values.each {|tag, val| self[tag] = val}
    end

    def initialized?
      fields.all? {|tag, field| field.initialized?(self) } && \
      extension_fields.all? {|tag, field| field.initialized?(self) }
    end

    def has_field?(tag_or_name)
      field = get_field(tag_or_name) || get_ext_field(tag_or_name)
      raise ArgumentError.new("unknown field: #{tag_or_name.inspect}") unless field
      @values.has_key?(field.name)
    end

    def ==(obj)
      return false unless obj.is_a? self.class
      each_field do |field, value|
        return false unless value == obj.send(field.name)
      end
      true
    end

    def clear!
      each_field do |field, value|
        field.clear self
      end
    end

    def dup
      ret = self.class.new
      each_field do |field, value|
        if field.repeated?
          field_array = ret.send(field.name)
          value.each do |v|
            field_array << (v.is_a?(Numeric) ? v : v.dup)
          end
        else
          ret.send("#{field.name}=", value.is_a?(Numeric) ? value : value.dup)
        end
      end
      ret
    end

    def inspect(indent=0)
      ret = ''
      i = '  ' * indent
      field_value_to_string = lambda do |field, value|
        ret +=
          if field.is_a? Protobuf::Field::MessageField
            if value.nil?
              if $DEBUG
                "#{i}#{field.name} {\n#{'  ' * (indent + 1)}nil\n#{i}}\n"
              else
                "#{i}#{field.name} {}\n"
              end
            else
              "#{i}#{field.name} {\n#{value.inspect(indent + 1)}#{i}}\n"
            end
          elsif field.is_a? Protobuf::Field::EnumField
	    if field.optional? and not has_field?(field.name)
	      ''
	    else
              "#{i}#{field.name}: #{field.type.name_by_value(value)}\n"
            end
          else
            if $DEBUG
              "#{i}#{field.name}: #{value.inspect}\n"
            else
              if field.optional? and not has_field?(field.name)
                ''
              else
                "#{i}#{field.name}: #{value.inspect}\n"
              end
            end
          end
      end
      each_field do |field, value|
        if field.repeated?
          value.each do |v| 
            field_value_to_string.call field, v
          end
        else 
          field_value_to_string.call field, value
        end
      end
      ret
    end

    def parse_from_string(string)
      parse_from StringIO.new(string)
    end

    def parse_from_file(filename)
      if filename.is_a? File
        parse_from filename
      else
        File.open(filename, 'r') do |f|
          parse_from f
        end
      end
    end

    def parse_from(stream)
      Protobuf::Decoder.decode stream, self
    end

    def serialize_to_string(string='')
      io = StringIO.new string
      serialize_to io
      io.string
    end
    alias to_s serialize_to_string

    def serialize_to_file(filename)
      if filename.is_a? File
        serialize_to filename
      else
        File.open(filename, 'w') do |f|
          serialize_to f
        end
      end
    end

    def serialize_to(stream)
      Protobuf::Encoder.encode stream, self
    end

    def merge_from(message)
      # TODO
      fields.each {|tag, field| merge_field tag, message[tag]}
      self.class.extension_fields.each {|tag, field| merge_field tag, message[tag]}
    end

    def set_field(tag, bytes)
      #get_field_by_tag(tag).set self, bytes # TODO
      (get_field_by_tag(tag) or get_ext_field_by_tag(tag)).set self, bytes
    end
    
    def merge_field(tag, value)
      #get_field_by_tag(tag).merge self, bytes #TODO
      (get_field_by_tag(tag) or get_ext_field_by_tag(tag)).merge self, value
    end
    
    def [](tag_or_name)
      if field = get_field(tag_or_name)
        send field.name
      elsif field = get_ext_field(tag_or_name)
        send field.name
      else
        raise NoMethodError.new("No such method: #{tag_or_name.inspect}")
      end
    end

    def []=(tag_or_name, value)
      if field = get_field(tag_or_name) and not field.repeated?
        send "#{field.name}=", value
      elsif field = get_ext_field(tag_or_name) and not field.repeated?
        send "#{field.name}=", value
      else
        raise NoMethodError.new("No such method: #{tag_or_name.inspect}")
      end
    end

    def fields; self.class.fields end
    def get_field_by_name(name); self.class.get_field_by_name(name) end
    def get_field_by_tag(tag); self.class.get_field_by_tag(tag) end
    def get_field(tag_or_name); self.class.get_field(tag_or_name) end

    def extension_fields; self.class.extension_fields end
    def get_ext_field_by_name(name); self.class.get_ext_field_by_name(name) end
    def get_ext_field_by_tag(tag); self.class.get_ext_field_by_tag(tag) end
    def get_ext_field(tag_or_name); self.class.get_ext_field(tag_or_name) end

    def each_field
      (fields.merge extension_fields).sort_by {|tag, field| tag}.each do |tag, field|
        yield field, send(field.name)
      end
    end
  end
end
