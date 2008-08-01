require 'protobuf/descriptor'

module Protobuf
  class Service < Descriptor
    def self.rpc(hash)
      raise NotImplementedError('TODO')
    end
  end
end
