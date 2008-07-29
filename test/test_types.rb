require 'test/unit'
require 'test/types'

class TypesTest < Test::Unit::TestCase
  def test_double
    # double fixed 64-bit
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type1 = 1 end
    assert_nothing_raised TypeError do types.type1 = 1.0 end
    assert_raise TypeError do types.type1 = '' end
    assert_nothing_raised do types.type1 = Protobuf::Field::DoubleField.max end
    assert_raise RangeError do types.type1 = Protobuf::Field::DoubleField.max + 1 end
    assert_nothing_raised do types.type1 = Protobuf::Field::DoubleField.min end
    assert_raise RangeError do types.type1 = Protobuf::Field::DoubleField.min - 1 end
  end

  def test_float
    # float 
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type2 = 1 end
    assert_nothing_raised do types.type2 = 1.0 end
    assert_raise TypeError do types.type2 = '' end
    assert_nothing_raised do types.type2 = Protobuf::Field::FloatField.max end
    assert_raise RangeError do types.type2 = Protobuf::Field::FloatField.max + 1 end
    assert_nothing_raised do types.type2 = Protobuf::Field::FloatField.min end
    assert_raise RangeError do types.type2 = Protobuf::Field::FloatField.min - 1 end
  end
end
