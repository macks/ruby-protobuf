require 'erb'

module Protobuf
  module Visitor
    class Base
      attr_reader :silent

      def log_writing(filename)
        puts "#{filename} writing..." unless silent
      end
    end

    class CreateMessageVisitor < Base
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
        rb_path.sub(/\.rb$/, '')
      end

      def create_files(filename, out_dir, file_create)
        if file_create
          log_writing filename
          FileUtils.mkpath File.dirname(filename)
          File.open(filename, 'w') {|file| file.write to_s}
        else
          to_s
        end
      end
    end

    class CreateRpcVisitor < Base
      attr_accessor :package, :services, :current_service, :file_contents

      def initialize
        @services = {}
        @create_file = true
        @file_contents = {}
      end

      def visit(node)
        node.accept_rpc_creator self
        self
      end

      def add_rpc(name, request, response)
        (@services[@current_service] ||= []) << [name, request.first, response.first]
      end

      def create_files(message_file, out_dir, create_file=true)
        @create_file = create_file
        default_port = 9999
        @services.each do |service_name, rpcs|
          underscored_name = underscore service_name.to_s
          message_module = package.map{|p| p.to_s.capitalize}.join('::')
          required_file = message_file.sub(/^\.\//, '').sub(/\.rb$/, '')

          create_bin out_dir, underscored_name, message_module, service_name, default_port
          create_service message_file, out_dir, underscored_name, message_module, 
            service_name, default_port, rpcs, required_file
          rpcs.each do |name, request, response|
            create_client out_dir, underscored_name, default_port, name, request, response, 
              message_module, required_file
          end
        end
        @file_contents
      end

      def create_bin(out_dir, underscored_name, module_name, service_name, default_port)
        bin_filename = "#{out_dir}/start_#{underscored_name}"
        bin_contents = template_erb('rpc_bin').result binding
        File.open(bin_filename, 'w') do |file| 
          log_writing bin_filename
          FileUtils.mkpath File.dirname(bin_filename)
          file.write bin_contents
        end if @create_file
        @file_contents[bin_filename] = bin_contents
      end

      def create_service(message_file, out_dir, underscored_name, module_name, service_name, 
        default_port, rpcs, required_file)
        service_filename = "#{out_dir}/#{underscored_name}.rb"
        service_contents = template_erb('rpc_service').result binding
        File.open(service_filename, 'w') do |file| 
          log_writing service_filename
          FileUtils.mkpath File.dirname(service_filename)
          file.write service_contents
        end if @create_file
        @file_contents[service_filename] = service_contents
      end

      def create_client(out_dir, underscored_name, default_port, name, request, response, 
        message_module, required_file)
        client_filename = "#{out_dir}/client_#{underscore name}.rb"
        client_contents = template_erb('rpc_client').result binding
        File.open(client_filename, 'w') do |file| 
          log_writing client_filename
          FileUtils.mkpath File.dirname(client_filename)
          file.write client_contents
        end if @create_file
        @file_contents[client_filename] = client_contents
      end

      private

      def underscore(str)
        str.to_s.gsub(/\B[A-Z]/, '_\&').downcase
      end

      def template_erb(template)
        ERB.new File.read("#{File.dirname(__FILE__)}/template/#{template}.erb"), nil, '-'
      end
    end
  end
end
