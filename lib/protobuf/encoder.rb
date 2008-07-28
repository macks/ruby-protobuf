module Protobuf
  class Encoder
    class <<self
      def encode(stream, message)
        self.new(stream, message).encode
      end
    end

    def initialize(stream=nil, message=nil)
      @stream, @message = stream, message
    end

    def encode(stream=@stream, message=@message)
    end
  end
end
