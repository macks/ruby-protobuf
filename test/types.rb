require 'protobuf/message'

module Test
  module Types
    
    class TestTypes < Protobuf::Message
      required :double, :type1, 1
      required :float, :type2, 2
      required :int32, :type3, 3
      required :int64, :type4, 4
      required :uint32, :type5, 5
      required :uint64, :type6, 6
      required :sint32, :type7, 7
      required :sint64, :type8, 8
      required :fixed32, :type9, 9
      required :fixed64, :type10, 10
      required :bool, :type11, 11
      required :string, :type12, 12
      required :bytes, :type13, 13
    end
  end
end
