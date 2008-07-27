require 'protobuf/message'

module Tutorial
  class Person < Protobuf::Message
    required :string, :name, 1
    required :int32, :id, 2
    optional :string, :email, 3

    module PhoneType
      MOBILE = 0
      HOME = 1
      WORK = 2
    end

    class PhoneNumber < Protobuf::Message
      required :string, :number, 1
      optional :PhoneType, :type, 2, {:default => :HOME}
    end

    repeated :PhoneNumber, :phone, 4
  end

  class AddressBook < Protobuf::Message
    repeated :Person, :person, 1
  end
end

puts :PERSON
person = Tutorial::Person.new
puts person.name.inspect
puts person.id.inspect
puts person.phone.inspect

puts :ADDRESS_BOOK
address_book = Tutorial::AddressBook.new
puts address_book.person.inspect
puts address_book.person.class.name
address_book.person << person
puts address_book.person.inspect
address_book.person << 1
puts address_book.person.inspect

