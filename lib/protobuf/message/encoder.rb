require 'protobuf/common/wire_type'
require 'protobuf/common/exceptions'

module Protobuf

  module Encoder

    module_function

    # Encode +message+ and write to +stream+.
    def encode(stream, message)
      raise NotInitializedError unless message.initialized?
      message.each_field do |field, value|
        next unless message.has_field?(field.name)

        if field.repeated?
          value.each do |val|
            write_pair(stream, field, val)
          end
        else
          write_pair(stream, field, value)
        end
      end
    end

    # Encode key and value, and write to +stream+.
    def write_pair(stream, field, value)
      key = (field.tag << 3) | field.wire_type
      key_bytes = Protobuf::Field::VarintField.encode(key)
      stream.write(key_bytes)
      bytes = field.encode(value)
      stream.write(bytes)
    end

  end
end
