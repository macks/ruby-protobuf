require 'protobuf/common/wire_type'

module Protobuf
  class InvalidWireType < StandardError; end

  class Decoder
    class <<self
      def decode(stream, message)
        self.new(stream, message).decode
      end
    end

    def initialize(stream=nil, message=nil)
      @stream, @message = stream, message
    end

    def decode(stream=@stream, message=@message)
      until stream.eof?
        tag, wire_type = read_key stream
        bytes =
          case wire_type
          when WireType::VARINT
            read_varint stream
          when WireType::FIXED64
            read_fixed64 stream
          when WireType::LENGTH_DELIMITED
            read_length_delimited stream
          when WireType::START_GROUP
            read_start_group stream
          when WireType::END_GROUP
            read_end_group stream
          when WireType::FIXED32
            read_fixed32 stream
          else
            raise InvalidWireType.new(wire_type)
          end
        message.set_field tag, bytes
      end
      message
    end

    protected

    def read_key(stream)
      bytes = read_varint stream
      #TODO 1 < bytes.size のときエラー
      wire_type = bytes[0] & 0b00000111
      tag = bytes[0] >> 3 # TODO
      [tag, wire_type]
    end

    def read_varint(stream)
      bytes = []
      begin
        byte = stream.readchar
        bytes << (byte & 0b01111111)
      end while byte >> 7 == 1
      bytes
    end

    def read_fixed64(stream)
      stream.read(8)
    end

    def read_length_delimited(stream)
      bytes = read_varint stream
      value_length = 0
      bytes.each_with_index do |byte, index|
        value_length |= byte << (7 * index)
      end
      value = stream.read value_length
      value.unpack('c*')
    end

    def read_start_group(stream)
      raise NotImplementedError.new('Group is duplecated.')
    end
 
    def read_end_group(stream)
      raise NotImplementedError.new('Group is duplecated.')
    end

    def read_fixed32(stream)
      stream.read(4)
    end
  end
end
