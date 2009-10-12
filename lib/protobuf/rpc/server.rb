require 'webrick/config'
require 'webrick/server'

module Protobuf
  module Rpc
    class Server < WEBrick::GenericServer
      def initialize(config={:Port => 9999}, default=WEBrick::Config::General)
        super(config, default)
        setup_handlers
      end

      def setup_handlers
        @handlers = {}
      end

      def get_handler(socket)
        @handlers[socket.readline.strip.to_sym]
      end

      def run(socket)
        handler = get_handler socket
        request = handler.request_class.new
        request.parse_from(socket)
        response = handler.response_class.new
        begin
          handler.process_request(request, response)
        rescue StandardError
          @logger.error $!
        ensure
          begin
            response.serialize_to(socket)
          rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ENOTCONN
            @logger.error $!
          end
        end
      end
    end
  end
end
