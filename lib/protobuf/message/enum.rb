require 'protobuf/descriptor/enum_descriptor'
require 'protobuf/message/protoable'

module Protobuf
  class Enum
    class <<self
      include Protoable

      def get_name_by_tag(tag)
        constants.find do |name|
          const_get(name) == tag
        end
      end

      def valid_tag?(tag)
        not get_name_by_tag(tag).nil?
      end

      def name_by_value(value)
        constants.find {|c| const_get(c) == value}
      end

      def descriptor
        @descriptor ||= Descriptor::EnumDescriptor.new(self)
      end
    end
  end
end
