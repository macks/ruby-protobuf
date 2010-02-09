module Protobuf
  module Util
    module_function

    def camelize(name)
      name.to_s.gsub(/(?:\A|_)(\w)/) { $1.upcase }
    end
  end
end
