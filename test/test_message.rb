require 'protobuf/message/message'
require 'test/addressbook'
require 'test/unit'

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

  def test_initialize_with_hash
    person = Tutorial::Person.new :name => 'Jiro', :id => 300, :email => 'jiro@ema.il'
    assert_equal 'Jiro', person.name
    assert_equal 300, person.id
    assert_equal 'jiro@ema.il', person.email
  end
end
