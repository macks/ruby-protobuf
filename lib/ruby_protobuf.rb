require 'protobuf/compiler/compiler'

class RubyProtobuf
  VERSION = '0.2.1'

  def start(proto_file, options)
    Protobuf::Compiler.compile(proto_file, (options[:proto_path] or '.'), (options[:out] or '.'))
  end
end
