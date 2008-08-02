module Protobuf
  class Descriptor
    def self.id2type(type_id)
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

    def self.id2label(label_id)
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

    class <<self
      def proto_type
        nil
      end

      def build(proto, opt={})
raise 'error' unless proto
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
    end
  end
end

=begin
tutorial = Object.const_set :Tutorial, Module.new
person = tutorial.const_set :Person, Class.new(Protobuf::Message)
person.required :string, :name, 1
person.required :int32, :id, 2
person.optional :string, :email, 3
phone_type = person.const_set :PhoneType, Class.new(Protobuf::Enum)
phone_type.const_set :MOBILE, 0
phone_type.const_set :HOME, 1
phone_type.const_set :WORK, 2
phone_number = person.const_set :PhoneNumber, Class.new(Protobuf::Message)
phone_number.required :string, :number, 1
phone_number.optional :PhoneType, :type, 2, {:default => :HOME}
person.repeated :PhoneNumber, :phone, 4
address_book = tutorial.const_set :AddressBook, Class.new(Protobuf::Message)
address_book.repeated :Person, :person, 1
=end
