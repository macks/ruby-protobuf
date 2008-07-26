require 'protobuf/decoder'

File.open('test/data/data.bin', 'r') do |f|
  ProtoBuf::Decoder.decode f
end

