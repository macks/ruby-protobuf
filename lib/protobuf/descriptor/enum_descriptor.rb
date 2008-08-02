#require 'protobuf/descriptor_proto'

module Protobuf
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
  end
end
