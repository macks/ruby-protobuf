require 'protobuf/wire_type'

module ProtoBuf
  class InvalidWireType < StandardError; end

  module WireFormat
    def to_varint
      value = 0
      each_with_index do |byte, index|
        value |= byte << (7 * index)
      end
    end

    def to_string
      pack 'U*'
    end
  end

  class Decoder
    class <<self
      def decode(stream)
        self.new(stream).decode
      end
    end

    def initialize(stream=nil)
      @stream = stream
    end

    def decode(stream=@stream)
      until stream.eof?
        field_number, wire_type = read_key stream
value =
        case wire_type
        when WireType::VARINT
          bytes = read_varint stream
          bytes.to_varint
        when WireType::FIXED64
          read_fixed64 stream
        when WireType::LENGTH_DELIMITED
          bytes = read_length_delimited stream
          bytes.to_string
        when WireType::START_GROUP
          read_start_group stream
        when WireType::END_GROUP
          read_end_group stream
        when WireType::FIXED32
          read_fixed32 stream
        else
          raise InvalidWiretype.new(wire_type)
        end

puts "#{field_number}: #{value}"
      end
    end

    protected

    def read_key(stream)
      bytes = read_varint stream
      wire_type = bytes[0] & 0b00000111
      field_number = bytes[0] >> 3 # TODO
      [field_number, wire_type]
    end

    def read_varint(stream)
      bytes = [].extend WireFormat
      begin
        byte = stream.readchar
        bytes << (byte & 0b01111111)
      end while byte >> 7 == 1
      bytes
    end

    def read_fixed64(stream)
      bytes = stream.read(2).unpack('c*').extend WireFormat
    end

    def read_length_delimited(stream)
      bytes = read_varint stream
      value_length = 0
      bytes.each_with_index do |byte, index|
        value_length |= byte << (7 * index)
      end
      value = stream.read value_length
      value.unpack('c*').extend WireFormat
    end

    def read_start_group(stream)
      raise 'Have not implemented'
    end
 
    def read_end_group(stream)
      raise 'Have not implemented'
    end

    def read_fixed32(stream)
      [stream.getc].extend WireFormat
    end
  end
end
