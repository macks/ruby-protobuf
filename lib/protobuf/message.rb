require 'stringio'
require 'protobuf/decoder'
require 'protobuf/encoder'
require 'protobuf/field'

module Protobuf
  class Message
    class <<self
      attr_reader :fields

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
        (@fields ||= {})[tag] = Protobuf::Field.build self, rule, type, name, tag, opts
      end

      def get_field_by_name(name)
        @fields.values.find {|field| field.name == name.to_sym}
      end

      def get_field_by_tag(tag)
        @fields[tag]
      end

      def get_field(tag_or_name)
        case tag_or_name
        when Integer
          get_field_by_tag tag_or_name
        when String, Symbol
          get_field_by_name tag_or_name
        else
          raise TypeError
        end
      end
    end

    def initialize
      fields.each do |tag, field|
        field.define_accessor self
      end
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

    def serialize_to_string(string)
      serialize_to StringIO.new(string)
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
      get_field_by_tag(tag).set self, bytes
    end
    
    def merge_field(tag, value)
      # TODO
      #get_field_by_tag(tag).merge self, bytes
    end
    
    def [](tag_or_name)
      if field = get_field(tag_or_name)
        send field.name
      else
        raise NoMethodError.new("No such method: #{tag_or_name}")
      end
    end

    def []=(tag_or_name, value)
      if field = get_field(tag_or_name) and not field.repeated?
        send "#{field.name}=", value
      else
        raise NoMethodError.new("No such method: #{tag_or_name}=")
      end
    end

    def fields; self.class.fields end
    def get_field_by_name(name); self.class.get_field_by_name(name) end
    def get_field_by_tag(tag); self.class.get_field_by_tag(tag) end
    def get_field(tag_or_name); self.class.get_field(tag_or_name) end
  end
end
