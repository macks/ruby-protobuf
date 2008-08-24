require 'pp'
require 'stringio'
require 'protobuf/message/decoder'
require 'protobuf/message/encoder'
require 'protobuf/message/field'
require 'protobuf/descriptor/descriptor'

module Protobuf
  OPTIONS = {}


  class Message
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
      attr_reader :fields

      def extensions(range)
        @extension_fields = ExtensionFields.new range
      end

      def defined_in(filepath)
        # TODO implement
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

      def define_field(rule, type, name, tag, opts={})
        field_hash = opts[:extension] ? extension_fields : (@fields ||= {})
        field_hash[tag] = Protobuf::Field.build self, rule, type, name, tag, opts
        #(@fields ||= {})[tag] = Protobuf::Field.build self, rule, type, name, tag, opts
      end

      def extension_tag?(tag)
        extension_fields.include_tag? tag
      end

      def extension_fields
        @extension_fields ||= ExtensionFields.new
      end

      def get_field_by_name(name)
        fields.values.find {|field| field.name == name.to_sym}
      end

      def get_field_by_tag(tag)
        fields[tag]
      end

      def get_field(tag_or_name)
        case tag_or_name
        when Integer; get_field_by_tag tag_or_name
        when String, Symbol; get_field_by_name tag_or_name
        else; raise TypeError
        end
      end

      #TODO merge to get_field_by_name
      def get_ext_field_by_name(name)
        extension_fields.values.find {|field| field.name == name.to_sym}
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
        else; raise TypeError
        end
      end

      def descriptor
        @descriptor ||= Protobuf::Descriptor::Descriptor.new(self)
      end
    end

    def initialize(values={})
      fields.each do |tag, field|
        unless field.ready?
          field = field.setup
          self.class.class_eval {@fields[tag] = field}
        end
        field.define_accessor self
      end

      # TODO
      self.class.extension_fields.each do |tag, field|
        unless field.ready?
          field = field.setup
          self.class.class_eval {@extension_fields[tag] = field}
        end
        field.define_accessor self
      end

      values.each {|tag, val| self[tag] = val}
    end

    def initialized?
      fields.to_a.inject(true) do |result, (tag, field)|
        result and field.initialized?(self)
      end and
      extension_fields.to_a.inject(true) do |result, (tag, field)|
        result and field.initialized?(self)
      end
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
          value.each do |v|
            ret[field.name] << (v.is_a?(Numeric) ? v : v.dup)
          end
        else
          ret[field.name] = value.is_a?(Numeric) ? value : value.dup
        end
      end
      ret
    end

    def to_s(indent=0)
      ret = ''
      i = '  ' * indent
      field_value_to_string = lambda do |field, value|
        ret +=
          if field.is_a? Protobuf::Field::MessageField
            "#{i}#{field.name} {\n#{value.to_s(indent + 1)}#{i}}\n"
          elsif field.is_a? Protobuf::Field::EnumField
            "#{i}#{field.name}: #{field.type.name_by_value(value)}\n"
          else
            "#{i}#{field.name}: #{value.inspect}\n"
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

    def set_field(tag, bytes)
      #get_field_by_tag(tag).set self, bytes
      (get_field_by_tag(tag) or get_ext_field_by_tag(tag)).set self, bytes
    end
    
    def merge_field(tag, value)
      # TODO
      #get_field_by_tag(tag).merge self, bytes
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

    def each_field(&block)
      (fields.merge extension_fields).to_a.sort{|(t1, f1), (t2, f2)| t1 <=> t2}.each do |tag, field|
        block.call field, self[tag]
      end
    end
  end
end
