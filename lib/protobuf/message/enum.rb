require 'protobuf/descriptor/enum_descriptor'

module Protobuf
  class Enum
    class <<self
      def get_name_by_tag(tag)
        constants.find do |name|
          class_eval(name) == tag
        end
      end

      def valid_tag?(tag)
        not get_name_by_tag(tag).nil?
      end

      def descriptor
        @descriptor ||= Protobuf::Descriptor::EnumDescriptor.new(self)
      end
    end
  end
end
