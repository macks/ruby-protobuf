module Protobuf
  module Rpc
    class Handler
      class <<self
        attr_reader :request_class, :response_class

        def request(request_class)
          @request_class = request_class
        end

        def response(response_class)
          @response_class = response_class
        end
      end
    end
  end
end
