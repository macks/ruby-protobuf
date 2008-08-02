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
        'Google::Protobuf::EnumDescriptorProto'
      end

      def build(proto, opt)
        mod = opt[:module]
        cls = mod.const_set proto.name, Class.new(Protobuf::Enum)
        proto.value.each do |value_proto|
          cls.const_set value_proto.name, value_proto.number
        end
      end
    end
  end
end
