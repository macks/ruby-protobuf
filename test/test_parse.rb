require 'test/unit'
require 'test/addressbook'

class ParseTest < Test::Unit::TestCase
  def test_parse
    person = Tutorial::Person.new
    person.parse_from_file 'test/data/data.bin'
    assert_equal 1234, person.id
    assert_equal 'John Doe', person.name
    assert_equal 'jdoe@example.com', person.email
  end
end
