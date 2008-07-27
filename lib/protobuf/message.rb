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
        @fields.values.find {|field| field.name == name}
      end

      def get_field_by_tag(tag)
        @fields[tag]
      end
    end

    def initialize
      fields.each do |tag, field|
        field.define_accessor self
      end
    end

    protected

    def fields; self.class.fields end
    def get_field_by_name(name); self.class.get_field_by_name(name) end
    def get_field_by_tag(tag); self.class.get_field_by_tag(tag) end
  end
end
