require 'protobuf/wire_type'

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
        key = (field.tag << 3) | field.wire_type
        key_bytes = Protobuf::Field::VarintField.get_bytes key
        #stream.write key_bytes.pack('C*')
        stream.write key_bytes

        if field.repeated?
          value.each do |val|
            bytes = field.get val
            #stream.write bytes.pack('C*')
            stream.write bytes
          end
        else
          bytes = field.get value
          #stream.write bytes.pack('C*')
          stream.write bytes
        end
      end
    end
  end
end
