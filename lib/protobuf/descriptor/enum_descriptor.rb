module Protobuf
  module Descriptor
    class EnumDescriptor
      def initialize(enum_class)
        @enum_class = enum_class
      end

      def proto_type
        Google::Protobuf::EnumDescriptorProto
      end

      def build(proto, opt)
        mod = opt[:module]
        cls = mod.const_set proto.name, Class.new(Protobuf::Enum)
        proto.value.each do |value_proto|
          cls.const_set value_proto.name, value_proto.number
        end
      end

      def unbuild(parent_proto)
        enum_proto = Google::Protobuf::EnumDescriptorProto.new
        enum_proto.name = @enum_class.name.split('::').last
        @enum_class.constants.each do |const|
          enum_value_proto = Google::Protobuf::EnumValueDescriptorProto.new
          enum_value_proto.name = const
          enum_value_proto.number = @enum_class.const_get const
          enum_proto.value << enum_value_proto
        end
        parent_proto.enum_type << enum_proto
      end
    end
  end
end
