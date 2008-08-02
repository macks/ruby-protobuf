require 'test/unit'
require 'protobuf/compiler/compiler'

class CompilerTest < Test::Unit::TestCase
  def test_compile
    assert_equal <<-eos.strip, Protobuf::Compiler.compile('test/addressbook.proto').strip
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'

module Tutorial
  
  class Person < ::Protobuf::Message
    required :string, :name, 1
    required :int32, :id, 2
    optional :string, :email, 3
    
    class PhoneType < ::Protobuf::Enum
      MOBILE = 0
      HOME = 1
      WORK = 2
    end
    
    class PhoneNumber < ::Protobuf::Message
      required :string, :number, 1
      optional :PhoneType, :type, 2, {:default => :HOME}
    end
    
    repeated :PhoneNumber, :phone, 4
  end
  
  class AddressBook < ::Protobuf::Message
    repeated :Person, :person, 1
  end
end
    eos
  end
end
