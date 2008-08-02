require 'protobuf/descriptor'

module Protobuf
  class Enum < Descriptor
    class <<self
      def get_name_by_tag(tag)
        constants.find do |name|
          class_eval(name) == tag
        end
      end

      def valid_tag?(tag)
        not get_name_by_tag(tag).nil?
      end

      def proto_type
        Google::Protobuf::EnumDescriptorProto
      end

      def build(proto, opt)
      end
    end
  end
end
