module Protobuf
  class Enum
    def self.get_name_by_tag(tag)
      constants.find do |name|
        class_eval(name) == tag
      end
    end

    def self.valid_tag?(tag)
      not get_name_by_tag(tag).nil?
    end
  end
end
