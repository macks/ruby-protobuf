require 'test/unit'
require 'test/proto/lowercase.pb'

class LowercaseTest < Test::Unit::TestCase
  def test_lowercase
    message = nil
    assert_nothing_raised { message = Test::LowerCase::LowerCamelCase::Baaz.new }
    assert_nothing_raised { message.x = Test::LowerCase::LowerCamelCase::Foo::Bar.new }
    assert_equal(Test::LowerCase::LowerCamelCase::Foo::Bar, message.get_field_by_name(:x).type)
  end

  def test_lowercased_enum_members
    klass = Test::LowerCase::LowerCamelCase::Baaaz
    assert_equal(0, klass::Abc)
    assert_equal(1, klass::Def)
    assert_equal(0, klass.values[:abc])
    assert_equal(1, klass.values[:def])
  end
end
