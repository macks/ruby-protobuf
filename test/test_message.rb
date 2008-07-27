require 'test/unit'
require 'protobuf/message'
require 'test/addressbook'

class MessageTest < Test::Unit::TestCase
  def test_bracketed_access
    person = Tutorial::Person.new
    name_tag = 1
    person[name_tag] = 'Ichiro'
    assert_equal 'Ichiro', person.name
    assert_equal 'Ichiro', person[name_tag]

    person[:id] = 100
    assert_equal 100, person.id
    person['id'] = 200
    assert_equal 200, person.id
    assert_equal 200, person[:id]
    assert_equal 200, person['id']
  end
end
