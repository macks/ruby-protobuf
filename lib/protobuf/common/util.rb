module Protobuf
  module Util
    module_function

    def camelize(name)
      name.to_s.gsub(/(?:\A|_)(\w)/) { $1.upcase }
    end

    def modulize(name)
      name.to_s.sub(/\A[a-z]/) {|c| c.upcase }
    end

    def underscore(name)
      name.to_s.gsub(/\B[A-Z]/, '_\&').downcase
    end
  end

  begin
    Version = File.read(File.dirname(__FILE__) + '/../../../VERSION').strip
  rescue
    Version = 'unknown'
  end
end
