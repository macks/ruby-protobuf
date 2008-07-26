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
        (@fields ||= {})[tag] = Protobuf::Field::BaseField.build self, rule, type, name, tag, opts
      end
    end

    def initialize
      self.class.fields.each do |tag, f|
        f.define_accessor_to self
      end
    end
  end
end
