require 'test/unit'
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'test/addressbook'

class StandardMessageTest < Test::Unit::TestCase
  def test_initialized
    person = Tutorial::Person.new
    assert !person.initialized?
    person.name = 'name'
    assert !person.initialized?
    person.id = 12
    assert person.initialized?
  end

  def test_clear
    person = Tutorial::Person.new
    person.name = 'name'
    person.id = 1234
    person.email = 'abc@cde.fgh'
    person.phone << Tutorial::Person::PhoneNumber.new
    person.clear!

    assert_nil person.name
    assert_nil person.id
    assert_equal '', person.email
    assert_equal 0, person.phone.size
  end
end

