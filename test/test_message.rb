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

  def test_defined_filenames
    assert Tutorial::Person.defined_filenames
    assert_equal 1, Tutorial::Person.defined_filenames.size
    assert Tutorial::Person.defined_filenames.first =~ %r{/.*/test/addressbook\.rb}
  end

  def test_proto_filenames
    assert Tutorial::Person.proto_filenames
    assert_equal 1, Tutorial::Person.proto_filenames.size
    assert_equal 'test/addressbook.proto', Tutorial::Person.proto_filenames.first
  end

  def test_proto_contents
    assert_equal <<-eos.strip, Tutorial::Person.proto_contents.values.first.strip
package tutorial;

message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    required string number = 1;
    optional PhoneType type = 2 [default = HOME];
  }

  repeated PhoneNumber phone = 4;

  extensions 100 to 200;
}

extend Person {
  optional int32 age = 100;
}

message AddressBook {
  repeated Person person = 1;
}
    eos
  end
end
