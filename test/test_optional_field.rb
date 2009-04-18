require 'test/unit'
require 'test/optional_field'

class OptionalFieldTest < Test::Unit::TestCase
  def test_accessor
    message = Test::Optional_field::Message.new

    # default values
    assert !message.has_field?(:number)
    assert_equal 20, message.number

    assert !message.has_field?(:text)
    assert_equal 'default string', message.text

    assert !message.has_field?(:enum)
    assert_equal 2, message.enum

    # assign values
    assert_nothing_raised { message.number = 100 }
    assert message.has_field?(:number)
    assert_equal 100, message.number

    assert_nothing_raised { message.text = 'abc' }
    assert message.has_field?(:text)
    assert_equal 'abc', message.text

    assert_nothing_raised { message.enum = Test::Optional_field::Message::Enum::A }
    assert message.has_field?(:enum)
    assert_equal 1, message.enum
  end

  def test_serialize
    message1 = Test::Optional_field::Message.new
    message2 = Test::Optional_field::Message.new

    # all fields are empty
    serialized_string = message1.to_s
    assert serialized_string.empty?
    message2.parse_from_string(serialized_string)
    assert_equal message1.number, message2.number
    assert_equal message1.text,   message2.text
    assert_equal message1.enum,   message2.enum
    assert !message2.has_field?(:number)
    assert !message2.has_field?(:text)
    assert !message2.has_field?(:enum)

    # assign the value whith is equal to default value
    message1 = Test::Optional_field::Message.new
    message1.number = message1.number
    message1.text   = message1.text
    message1.enum   = message1.enum
    serialized_string = message1.to_s
    assert !serialized_string.empty?

    # set some fields
    message1 = Test::Optional_field::Message.new
    message1.number = 100
    message1.text   = 'new text'
    serialized_string = message1.to_s
    message2.parse_from_string(serialized_string)
    assert_equal message1.number, message2.number
    assert_equal message1.text,   message2.text
    assert_equal message1.enum,   message2.enum
    assert  message2.has_field?(:number)
    assert  message2.has_field?(:text)
    assert !message2.has_field?(:enum)
  end
end
