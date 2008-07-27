require 'test/unit'
require 'protobuf/message'
require 'test/addressbook'

class DecoderTest < Test::Unit::TestCase
  def test_decode
    person = Tutorial::Person.new
    person.parse_from_file 'test/data/data.bin'
    assert_equal 1234, person.id
    assert_equal 'John Doe', person.name
    assert_equal 'jdoe@example.com', person.email
  end
end
