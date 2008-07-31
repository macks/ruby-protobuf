module Tutorial
  class Person < Protobuf::Message
    required :string, :name, 1
    required :int32, :id, 2
    optional :string, :email, 3

    class PhoneType < Protobuf::Enum
      MOBILE = 0
      HOME = 1
      WORK = 2
    end

    class PhoneNumber < Protobuf::Message
      required :string, :number, 1
      optional :PhoneType, :type, 2, {:default => :HOME}
    end

    repeated :PhoneNumber, :phone, 4

    # Extensions
    #extensions Protobuf::Extend.min..100
    #extensions 100..Protobuf::Extend.max
    #extensions 100..199
    #class Foo < Protobuf::Extend
    #  optional :int32, :bar, 126
    #end
  end

  class AddressBook < Protobuf::Message
    repeated :Person, :person, 1
  end

  # Defining Services
  #class SearchService < Protobuf::Service
  #  rpc :Search => :SearchRequest, :returns => :SearchResponse
  #end

  # Options
  #option :optimize_for => :SPEED
  #option :java_package => 'com.example.foo'
end
