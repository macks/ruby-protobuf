require 'socket'

module Protobuf
  module Rpc
    class Client
      def initialize(host, port)
        @host, @port = host, port
      end

      def call(name, request, response)
        socket = TCPSocket.open(@host, @port)
        socket.write "#{name}\n"
        request.serialize_to(socket)
        socket.close_write
        response.parse_from(socket)
      end
    end
  end
end
