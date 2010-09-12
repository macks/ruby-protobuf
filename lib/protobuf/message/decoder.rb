require 'protobuf/common/wire_type'
require 'protobuf/common/exceptions'

module Protobuf

  module Decoder

    module_function

    READ_METHODS = [
      :read_varint,           # 0: Varint
      :read_fixed64,          # 1: 64 bit
      :read_length_delimited, # 2: Length-delimited
      :read_start_group,      # 3: Start group
      :read_end_group,        # 4: End group
      :read_fixed32,          # 5: 32 bit
    ]

    # Read bytes from +stream+ and pass to +message+ object.
    def decode(stream, message)
      until stream.eof?
        tag, wire_type = read_key(stream)
        field = message.get_field_by_tag(tag)

        method = READ_METHODS[wire_type]
        raise InvalidWireType, "Unknown wire type: #{wire_type}" unless method
        value = send(method, stream)

        if field.nil?
          # ignore unknown field
        elsif field.repeated?
          array = message.__send__(field.name)
          if wire_type == WireType::LENGTH_DELIMITED && WireType::PACKABLE_TYPES.include?(field.wire_type)
            # packed
            s = StringIO.new(value)
            m = READ_METHODS[field.wire_type]
            until s.eof?
              array << field.decode(send(m, s))
            end
          else
            # non-packed
            array << field.decode(value)
          end
        else
          message.__send__("#{field.name}=", field.decode(value))
        end
      end
      message
    end

    # Read key pair (tag and wire-type) from +stream+.
    def read_key(stream)
      bits = read_varint(stream)
      wire_type = bits & 0x07
      tag = bits >> 3
      [tag, wire_type]
    end

    # Read varint integer value from +stream+.
    def read_varint(stream)
      read_method = stream.respond_to?(:readbyte) ? :readbyte : :readchar
      value = index = 0
      begin
        byte = stream.__send__(read_method)
        value |= (byte & 0x7f) << (7 * index)
        index += 1
      end while (byte & 0x80).nonzero?
      value
    end

    # Read 32-bit string value from +stream+.
    def read_fixed32(stream)
      stream.read(4)
    end

    # Read 64-bit string value from +stream+.
    def read_fixed64(stream)
      stream.read(8)
    end

    # Read length-delimited string value from +stream+.
    def read_length_delimited(stream)
      value_length = read_varint(stream)
      stream.read(value_length)
    end

    # Not implemented.
    def read_start_group(stream)
      raise NotImplementedError, 'Group is deprecated.'
    end

    # Not implemented.
    def read_end_group(stream)
      raise NotImplementedError, 'Group is deprecated.'
    end

  end
end
