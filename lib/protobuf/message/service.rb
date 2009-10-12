module Protobuf
  class Service
    class <<self
      def rpc(hash)
        raise NotImplementedError, 'TODO'
      end
    end
  end
end
