require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'
module Google
  module Protobuf
    ::Protobuf::OPTIONS[:java_package] = :"com.google.protobuf"
    ::Protobuf::OPTIONS[:java_outer_classname] = :"DescriptorProtos"
    ::Protobuf::OPTIONS[:optimize_for] = :SPEED
    class FileDescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      optional :string, :package, 2
      repeated :string, :dependency, 3
      repeated :DescriptorProto, :message_type, 4
      repeated :EnumDescriptorProto, :enum_type, 5
      repeated :ServiceDescriptorProto, :service, 6
      repeated :FieldDescriptorProto, :extension, 7
      optional :FileOptions, :options, 8
    end
    class DescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      repeated :FieldDescriptorProto, :field, 2
      repeated :FieldDescriptorProto, :extension, 6
      repeated :DescriptorProto, :nested_type, 3
      repeated :EnumDescriptorProto, :enum_type, 4
      class ExtensionRange < ::Protobuf::Message
        optional :int32, :start, 1
        optional :int32, :end, 2
      end
      repeated :ExtensionRange, :extension_range, 5
      optional :MessageOptions, :options, 7
    end
    class FieldDescriptorProto < ::Protobuf::Message
      class Type < ::Protobuf::Enum
        TYPE_DOUBLE = 1
        TYPE_FLOAT = 2
        TYPE_INT64 = 3
        TYPE_UINT64 = 4
        TYPE_INT32 = 5
        TYPE_FIXED64 = 6
        TYPE_FIXED32 = 7
        TYPE_BOOL = 8
        TYPE_STRING = 9
        TYPE_GROUP = 10
        TYPE_MESSAGE = 11
        TYPE_BYTES = 12
        TYPE_UINT32 = 13
        TYPE_ENUM = 14
        TYPE_SFIXED32 = 15
        TYPE_SFIXED64 = 16
        TYPE_SINT32 = 17
        TYPE_SINT64 = 18
      end
      class Label < ::Protobuf::Enum
        LABEL_OPTIONAL = 1
        LABEL_REQUIRED = 2
        LABEL_REPEATED = 3
      end
      optional :string, :name, 1
      optional :int32, :number, 3
      optional :Label, :label, 4
      optional :Type, :type, 5
      optional :string, :type_name, 6
      optional :string, :extendee, 2
      optional :string, :default_value, 7
      optional :FieldOptions, :options, 8
    end
    class EnumDescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      repeated :EnumValueDescriptorProto, :value, 2
      optional :EnumOptions, :options, 3
    end
    class EnumValueDescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      optional :int32, :number, 2
      optional :EnumValueOptions, :options, 3
    end
    class ServiceDescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      repeated :MethodDescriptorProto, :method, 2
      optional :ServiceOptions, :options, 3
    end
    class MethodDescriptorProto < ::Protobuf::Message
      optional :string, :name, 1
      optional :string, :input_type, 2
      optional :string, :output_type, 3
      optional :MethodOptions, :options, 4
    end
    class FileOptions < ::Protobuf::Message
      optional :string, :java_package, 1
      optional :string, :java_outer_classname, 8
      optional :bool, :java_multiple_files, 10, {:default => :false}
      class OptimizeMode < ::Protobuf::Enum
        SPEED = 1
        CODE_SIZE = 2
      end
      optional :OptimizeMode, :optimize_for, 9, {:default => :CODE_SIZE}
    end
    class MessageOptions < ::Protobuf::Message
      optional :bool, :message_set_wire_format, 1, {:default => :false}
    end
    class FieldOptions < ::Protobuf::Message
      optional :CType, :ctype, 1
      class CType < ::Protobuf::Enum
        CORD = 1
        STRING_PIECE = 2
      end
      optional :string, :experimental_map_key, 9
    end
    class EnumOptions < ::Protobuf::Message
    end
    class EnumValueOptions < ::Protobuf::Message
    end
    class ServiceOptions < ::Protobuf::Message
    end
    class MethodOptions < ::Protobuf::Message
    end
  end
end
