require 'protobuf/message'
require 'protobuf/enum'

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
  end

  class AddressBook < Protobuf::Message
    repeated :Person, :person, 1
  end
end

puts :PHONE_NUMBER
phone_number = Tutorial::Person::PhoneNumber.new
phone_number.type = Tutorial::Person::PhoneType.MOBILE
phone_number.type = Tutorial::Person::PhoneType.HOME
phone_number.type = Tutorial::Person::PhoneType.WORK
phone_number.type = 0
phone_number.type = 1
phone_number.type = 2
begin
  phone_number.type = 3
rescue TypeError
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
begin
  address_book.person << 1
  raise ArgumentError
rescue TypeError
end
puts address_book.person.inspect

