module Protobuf
  class FieldDescriptor
    def initialize(field_class)
      @field_class = field_class
    end

    def proto_type
      'Google::Protobuf::FieldDescriptorProto'
    end

    def build(proto, opt={})
      cls = opt[:class]
      rule = Protobuf::Descriptor.id2label proto.label
      type = Protobuf::Descriptor.id2type proto.type
      type = proto.type_name.to_sym if [:message, :enum].include? type
      opts = {}
      opts[:default] = proto.default_value if proto.default_value
      cls.define_field rule, type, proto.name, proto.number, opts
    end
  end
end

