require 'test/unit'
require 'test/addressbook'

class SerializeTest < Test::Unit::TestCase
  def test_serialize
    person = Tutorial::Person.new
    person.id = 4321
    person.name = 'Jane Smith'
    person.email = 'jsmith@example.com'
    phone = Tutorial::Person::PhoneNumber.new
    phone.number = '444-3210'
    phone.type = Tutorial::Person::PhoneType::WORK
    person.phone << phone
    File.open('data2.bin', 'w') do |f|
      person.serialize_to f
    end
    #person.serialize_to $stdout
  end
end
