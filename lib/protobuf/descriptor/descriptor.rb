module Protobuf
  module Descriptor
    class Descriptor
      def initialize(message_class)
        @message_class = message_class
      end

      def proto_type
        'Google::Protobuf::DescriptorProto'
      end

      def build(proto, opt={})
        mod = opt[:module]
        cls = mod.const_set proto.name, Class.new(@message_class)
        proto.nested_type.each do |message_proto|
          Protobuf::Message.descriptor.build message_proto, :module => cls
        end
        proto.enum_type.each do |enum_proto|
          Protobuf::Enum.descriptor.build enum_proto, :module => cls
        end
        proto.field.each do |field_proto|
          Protobuf::Field::BaseField.descriptor.build field_proto, :class => cls
        end
      end
    end
  end
end

