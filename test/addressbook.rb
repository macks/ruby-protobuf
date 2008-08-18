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
    
    #extensions 100..200
  end
  
  # see: addressbool_ext.rb
  #class Person < ::Protobuf::Message
  #  optional :int32, :age, 100, :extension => true
  #end
  
  class AddressBook < ::Protobuf::Message
    repeated :Person, :person, 1
  end

  #class SearchService < Protobuf::Service
  #  rpc :Search, :request => :SearchRequest, :response => :SearchResponse
  #end

  #Protobuf::OPTIONS[:optimize_for] = :SPEED
  #Protobuf::OPTIONS[:java_package] = :'com.example.foo'
end

=begin
tutorial = Object.const_set :Tutorial, Module.new
person = tutorial.const_set :Person, Class.new(Protobuf::Message)
person.required :string, :name, 1
person.required :int32, :id, 2
person.optional :string, :email, 3
phone_type = person.const_set :PhoneType, Class.new(Protobuf::Enum)
phone_type.const_set :MOBILE, 0
phone_type.const_set :HOME, 1
phone_type.const_set :WORK, 2
phone_number = person.const_set :PhoneNumber, Class.new(Protobuf::Message)
phone_number.required :string, :number, 1
phone_number.optional :PhoneType, :type, 2, {:default => :HOME}
person.repeated :PhoneNumber, :phone, 4
address_book = tutorial.const_set :AddressBook, Class.new(Protobuf::Message)
address_book.repeated :Person, :person, 1
=end
