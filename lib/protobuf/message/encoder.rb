require 'protobuf/common/wire_type'

module Protobuf
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
      message.each_field do |field, value|
        next unless value # TODO

        if field.repeated?
          value.each do |val|
            write_pair field, val, stream
          end
        else
          write_pair field, value, stream
        end
      end
    end

    def write_pair(field, value, stream)
      key = (field.tag << 3) | field.wire_type
      key_bytes = Protobuf::Field::VarintField.get_bytes key
      stream.write key_bytes
      bytes = field.get value
      stream.write bytes
    end
  end
end
