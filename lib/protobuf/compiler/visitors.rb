module Protobuf
  module Visitor
    class CreateMessageVisitor
      attr_accessor :indent, :context

      def initialize(proto_dir='.', out_dir='.')
        @proto_dir, @out_dir = proto_dir, out_dir
        @indent = 0
        @context = []
      end

      def write(str)
        ruby << "#{'  ' * @indent}#{str}"
      end

      def increment
        @indent += 1
      end

      def decrement
        @indent -= 1
      end

      def close_ruby
        while 0 < indent
          decrement
          write 'end'
        end
      end

      def ruby
        @ruby ||= []
      end

      def to_s
        @ruby.join "\n"
      end

      def in_context(klass, &block)
        increment
        context.push klass
        block.call
        context.pop
        decrement
      end

      def visit(node)
        node.accept_message_creator self 
        self
      end

      def required_message_from_proto(proto_file)
        rb_path = proto_file.sub(/\.proto$/, '.rb')
        unless File.exist?("#{@out_dir}/#{rb_path}")
          Compiler.compile proto_file, @proto_dir, @out_dir
        end
        rb_path.sub /\.rb$/, ''
      end
    end

    class CreateRpcVisitor
      attr_accessor :package, :services, :current_service

      def initialize
        @services = {}
      end

      def visit(node)
        node.accept_rpc_creator self
        self
      end

      def add_rpc(name, request, response)
        (@services[@current_service] ||= []) << [name, request.first, response.first]
      end

      def create_files(message_file, out_dir)
        default_port = 9999
        @services.each do |service_name, rpcs|
          underscored_name = underscore service_name.to_s
          message_module = package.map{|p| p.to_s.capitalize}.join('::')
          required_file = message_file.sub(/^\.\//, '').sub(/\.rb$/, '')

          create_bin out_dir, underscored_name, message_module, service_name, default_port
# TODO shold handle more than one rpc
          create_service message_file, out_dir, underscored_name, message_module, 
            service_name, default_port, rpcs, required_file
          rpcs.each do |name, request, response|
            create_client out_dir, underscored_name, default_port, name, request, response, message_module, required_file
          end
        end
      end

      def create_bin(out_dir, underscored_name, module_name, service_name, default_port)
        bin_filename = "#{out_dir}/start_#{underscored_name}"
        bin_contents = <<-eos
#!/usr/bin/ruby
require '#{underscored_name}'

#{module_name}::#{service_name}.new(:port => #{default_port}).start
        eos
puts
puts '------------------'
puts bin_filename
puts bin_contents
      end

      def create_service(message_file, out_dir, underscored_name, module_name, service_name, default_port, rpcs, required_file)
        name, request, response = rpcs.first
        service_filename = "#{out_dir}/#{underscored_name}.rb"
        service_contents = <<-eos
require 'protobuf/rpc/server'
require 'protobuf/rpc/handler'
require '#{required_file}'

class #{module_name}::#{name}Handler < Protobuf::Rpc::Handler
  request #{module_name}::#{request}
  response #{module_name}::#{response}
  
  def self.process_request(request, response)
    # TODO: edit this method
  end
end

class #{module_name}::#{service_name} < Protobuf::Rpc::Server
  def setup_handlers
    @handlers = {
      :#{underscore name} => #{module_name}::#{name}Handler
    }
  end
end
        eos
puts
puts '------------------'
puts service_filename
puts service_contents
      end

      def create_client(out_dir, underscored_name, default_port, name, request, response, message_module, required_file)
        client_filename = "#{out_dir}/client_#{underscore name}.rb"
        client_contents = <<-eos
#!/usr/bin/ruby
require 'protobuf/rpc/client'
require '#{required_file}'

# build request
#{underscore request} = #{message_module}::#{request}.new
# TODO: setup a request
raise StandardError.new('setup a request')

# create blunk response
#{underscore response} = #{message_module}::#{response}.new

# execute rpc
Protobuf::Rpc::Client.new('localhost', #{default_port}).call :#{underscore name}, #{underscore request}, #{underscore response}

# show response
puts #{underscore response}
        eos

puts
puts '------------------'
puts client_filename
puts client_contents
      end

      private

      def underscore(str)
        str.to_s.gsub(/\B[A-Z]/, '_\&').downcase
      end
    end
  end
end
