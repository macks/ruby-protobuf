require 'protobuf/common/wire_type'

module Protobuf
  class NotInitializedError < StandardError; end

  class Encoder
    class <<self
      def encode(stream, message)
        self.new(stream, message).encode
      end
    end

    def initialize(stream=nil, message=nil)
      @stream, @message = stream, message
    end

    def encode(stream=@stream, message=@message)
      raise NotInitializedError unless message.initialized?
      message.each_field do |field, value|
        next unless message.has_field?(field.name)

        if field.repeated?
          value.each do |val|
            write_pair(field, val, stream)
          end
        else
          write_pair(field, value, stream)
        end
      end
    end

    def write_pair(field, value, stream)
      key = (field.tag << 3) | field.wire_type
      key_bytes = Protobuf::Field::VarintField.encode(key)
      stream.write(key_bytes)
      bytes = field.get(value)
      stream.write(bytes)
    end
  end
end
