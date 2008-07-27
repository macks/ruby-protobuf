require 'test/unit'
require 'protobuf/decoder'

class DecoderTest < Test::Unit::TestCase
  def test_decode
    File.open('test/data/data.bin', 'r') do |f|
      ProtoBuf::Decoder.decode f
    end
  end
end
