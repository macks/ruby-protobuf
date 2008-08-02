module Protobuf
  class Descriptor
    class <<self
      def id2type(type_id)
        require 'protobuf/descriptor_proto'
        case type_id
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_DOUBLE
          :double
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_FLOAT
          :float
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_INT64
          :int64
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_UINT64
          :unit64
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_INT32
          :int64
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_FIXED64
          :fixed64
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_FIXED32
          :fixed32
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_BOOL
          :bool
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_STRING
          :string
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_GROUP
          :group
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_MESSAGE
          :message
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_BYTES
          :bytes
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_UINT32
          :uint32
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_ENUM
          :enum
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_SFIXED32
          :sfixed32
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_SFIXED64
          :sfixed64
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_SINT32
          :sint32
        when Google::Protobuf::FieldDescriptorProto::Type::TYPE_SINT64
          :sint64
        else
          raise ArgumentError.new("Invalid type: #{proto.type}")
        end
      end

      def id2label(label_id)
        require 'protobuf/descriptor_proto'
        case label_id
        when Google::Protobuf::FieldDescriptorProto::Label::LABEL_REQUIRED
          :required
        when Google::Protobuf::FieldDescriptorProto::Label::LABEL_OPTIONAL
          :optional
        when Google::Protobuf::FieldDescriptorProto::Label::LABEL_REPEATED
          :repeated
        else
          raise ArgumentError.new("Invalid label: #{proto.label}")
        end
      end

      def proto_type
        nil
      end

      def build(proto, opt={})
        acceptable_descriptor(proto).build proto
      end

      def acceptable_descriptor(proto)
        ObjectSpace.each_object(Class) do |cls|
          if cls.superclass == Protobuf::Descriptor and cls.proto_type == proto.class.name
            return cls
          end
        end
        raise TypeError.new(proto.class.name)
      end
    end
  end

  class FileDescriptor < Descriptor
    class <<self
      def proto_type
        'Google::Protobuf::FileDescriptorProto'
      end

      def build(proto, opt={})
        mod = Object
        if package = proto.package and not package.empty?
          module_names = package.split '::'
          module_names.each do |module_name|
            mod = mod.const_set module_name, Module.new
          end
        end
        proto.message_type.each do |message_proto|
          Protobuf::Message.build message_proto, :module => mod
        end
        proto.enum_type.each do |enum_proto|
          Protobuf::Enum.build enum_proto, :module => mod
        end
      end

      def unbuild(descriptors)
        descriptors = [descriptors] unless descriptors.is_a? Array
        proto = Google::Protobuf::FileDescriptorProto.new
        proto.package = descriptors.first.to_s.split('::')[0..-2].join('::') if descriptors.first.to_s =~ /::/
        descriptors.each do |descriptor|
          #descriptor.unbuild proto
        end
        proto
      end
    end
  end
end
