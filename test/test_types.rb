require 'test/unit'
require 'test/types'

class TypesTest < Test::Unit::TestCase
  def test_serialize
    types = Test::Types::TestTypes.new
    types.type1 = 0.01
    types.type2 = 0.1 
    types.type3 = 1
    types.type4 = 10 
    types.type5 = 100
    types.type6 = 1000
    types.type7 = -1
    types.type8 = -10
    types.type9 = 10000
    types.type10 = 100000
    types.type11 = false
    types.type12 = 'hello all types'
    #types.type13 = 
    serialized_string = types.serialize_to_string

    types2 = Test::Types::TestTypes.new
    types2.parse_from_string serialized_string
    assert_in_delta 0.01, types2.type1, 0.00001
    assert_in_delta 0.1, types2.type2, 0.00001
    assert_equal 1, types2.type3
    assert_equal 10, types2.type4
    assert_equal 100, types2.type5
    assert_equal 1000, types2.type6
    assert_equal(-1, types2.type7)
    assert_equal(-10, types2.type8)
    assert_equal 10000, types2.type9
    assert_equal 100000, types2.type10
    assert !types2.type11
    assert_equal 'hello all types', types2.type12
    #types2.type13
  end

  def test_parse
    types = Test::Types::TestTypes.new
    types.parse_from_file 'test/data/types.bin'
    assert_in_delta 0.01, types.type1, 0.00001
    assert_in_delta 0.1, types.type2, 0.00001
    assert_equal 1, types.type3
    assert_equal 10, types.type4
    assert_equal 100, types.type5
    assert_equal 1000, types.type6
    assert_equal(-1, types.type7)
    assert_equal(-10, types.type8)
    assert_equal 10000, types.type9
    assert_equal 100000, types.type10
    assert_equal false, types.type11
    assert_equal 'hello all types', types.type12
    # types.type13
  end

  def test_double
    # double fixed 64-bit
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type1 = 1 end
    assert_nothing_raised do types.type1 = 1.0 end
    assert_raise TypeError do types.type1 = '' end
    assert_nothing_raised do types.type1 = Protobuf::Field::DoubleField.max end
    assert_raise RangeError do types.type1 = Protobuf::Field::DoubleField.max * 2 end
    assert_nothing_raised do types.type1 = Protobuf::Field::DoubleField.min end
    assert_raise RangeError do types.type1 = Protobuf::Field::DoubleField.min * 2 end
  end

  def test_float
    # float fixed 32-bit
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type2 = 1 end
    assert_nothing_raised do types.type2 = 1.0 end
    assert_raise TypeError do types.type2 = '' end
    assert_nothing_raised do types.type2 = Protobuf::Field::FloatField.max end
    assert_raise RangeError do types.type2 = Protobuf::Field::FloatField.max * 2 end
    assert_nothing_raised do types.type2 = Protobuf::Field::FloatField.min end
    assert_raise RangeError do types.type2 = Protobuf::Field::FloatField.min * 2 end
  end

  def test_int32
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type3 = 1 end
    assert_nothing_raised do types.type3 = -1 end
    assert_raise TypeError do types.type3 = 1.0 end
    assert_raise TypeError do types.type3 = '' end
  end

  def test_int64
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type4 = 1 end
    assert_nothing_raised do types.type4 = -1 end
    assert_raise TypeError do types.type4 = 1.0 end
    assert_raise TypeError do types.type4 = '' end
  end

  def test_uint32
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type5 = 1 end
    assert_raise RangeError do types.type5 = -1 end
    assert_raise TypeError do types.type5 = 1.0 end
    assert_raise TypeError do types.type5 = '' end
  end

  def test_uint64
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type6 = 1 end
    assert_raise RangeError do types.type6 = -1 end
    assert_raise TypeError do types.type6 = 1.0 end
    assert_raise TypeError do types.type6 = '' end
  end

  def test_sint32
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type7 = 1 end
    assert_nothing_raised do types.type7 = -1 end
    assert_raise TypeError do types.type7 = 1.0 end
    assert_raise TypeError do types.type7 = '' end
  end

  def test_sint64
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type8 = 1 end
    assert_nothing_raised do types.type8 = -1 end
    assert_raise TypeError do types.type8 = 1.0 end
    assert_raise TypeError do types.type8 = '' end
  end

  def test_fixed32
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type9 = 1 end
    assert_raise TypeError do types.type9 = 1.0 end
    assert_raise TypeError do types.type9 = '' end
    assert_nothing_raised do types.type9 = Protobuf::Field::Fixed32Field.max end
    assert_raise RangeError do types.type9 = Protobuf::Field::Fixed32Field.max + 1 end
    assert_nothing_raised do types.type9 = Protobuf::Field::Fixed32Field.min end
    assert_raise RangeError do types.type9 = Protobuf::Field::Fixed32Field.min - 1 end
  end

  def test_fixed64
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type10 = 1 end
    assert_raise TypeError do types.type10 = 1.0 end
    assert_raise TypeError do types.type10 = '' end
    assert_nothing_raised do types.type10 = Protobuf::Field::Fixed64Field.max end
    assert_raise RangeError do types.type10 = Protobuf::Field::Fixed64Field.max + 1 end
    assert_nothing_raised do types.type10 = Protobuf::Field::Fixed64Field.min end
    assert_raise RangeError do types.type10 = Protobuf::Field::Fixed64Field.min - 1 end
  end

  def test_bool
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type11 = true end
    assert_nothing_raised do types.type11 = false end
    assert_raise TypeError do types.type11 = nil end
    assert_raise TypeError do types.type11 = 0 end
    assert_raise TypeError do types.type11 = '' end
  end

  def test_string
    types = Test::Types::TestTypes.new
    assert_nothing_raised do types.type12 = '' end
    assert_nothing_raised do types.type12 = 'hello' end
    assert_raise TypeError do types.type12 = nil end
    assert_raise TypeError do types.type12 = 0 end
    assert_raise TypeError do types.type12 = true end
  end

  def test_bytes
    types = Test::Types::TestTypes.new
    # TODO
=begin
    assert_nothing_raised do types.type13 = '' end
    assert_nothing_raised do types.type13 = 'hello' end
    assert_raise TypeError do types.type13 = nil end
    assert_raise TypeError do types.type13 = 0 end
    assert_raise TypeError do types.type13 = true end
=end
  end
end
