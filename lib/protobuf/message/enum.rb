require 'protobuf/descriptor/enum_descriptor'
require 'protobuf/message/protoable'

module Protobuf
  class Enum
    class <<self
      include Protoable

      def name_by_value(value)
        constants.find {|c| const_get(c) == value}
      end

      alias get_name_by_tag name_by_value

      def valid_tag?(tag)
        !! name_by_value(tag)
      end

      def descriptor
        @descriptor ||= Descriptor::EnumDescriptor.new(self)
      end
    end
  end
end
