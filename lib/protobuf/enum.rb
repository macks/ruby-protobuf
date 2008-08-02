require 'protobuf/descriptor'
require 'protobuf/descriptor/enum_descriptor'

module Protobuf
  class Enum
    class <<self
      def get_name_by_tag(tag)
        constants.find do |name|
          class_eval(name) == tag
        end
      end

      def valid_tag?(tag)
        not get_name_by_tag(tag).nil?
      end

      def descriptor
        @descriptor ||= Protobuf::EnumDescriptor.new(self)
      end

      def proto_type
        descriptor.proto_type
      end

      def build(proto, opt)
        descriptor.build proto, opt
      end
    end
  end
end
