require 'test/unit'
require 'test/addressbook_ext.rb'

class ExtensionTest < Test::Unit::TestCase
  def test_accessor
    assert TutorialExt::Person.extension_fields.to_a.map{|t, f| f.name}.include?(:age)
    person = TutorialExt::Person.new
    assert_nothing_raised {person.age = 100}
    assert 100, person.age
    #assert 100, person.extension.age
    #assert_nothing_raised {person.extension.age = 200}
    #assert 200, person.age
    #assert 200, person.extension.age
  end

  def test_serialize
    # TODO
  end

  def test_parse
    # TODO
  end
end
