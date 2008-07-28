require 'test/unit'
require 'protobuf/compiler'

class CompilerTest < Test::Unit::TestCase
  def test_compile
    Protobuf::Compiler.compile '../protoc/addressbook.proto'
  end
end
