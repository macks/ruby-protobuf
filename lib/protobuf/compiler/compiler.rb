require 'fileutils'
require 'protobuf/compiler/proto_parser'
require 'protobuf/compiler/nodes'
require 'protobuf/compiler/visitors'

module Protobuf
  class Compiler
    def self.compile(proto_file, proto_dir='.', out_dir='.', file_create=true)
      self.new.compile proto_file, proto_dir, out_dir, file_create
    end

    def compile(proto_file, proto_dir='.', out_dir='.', file_create=true)
      create_message proto_file, proto_dir, out_dir, file_create
      create_rpc proto_file, proto_dir, out_dir, file_create
    end

    def create_message(proto_file, proto_dir='.', out_dir='.', file_create=true)
      rb_file = "#{out_dir}/#{proto_file.sub(/\.proto$/, '.rb')}"
      proto_path = validate_existence proto_file, proto_dir

      message_visitor = Protobuf::Visitor::CreateMessageVisitor.new proto_file, proto_dir, out_dir
      message_visitor.attach_proto = file_create #TODO file_create is temporarily set as an attach_proto flag
      File.open proto_path, 'r' do |file|
        message_visitor.visit Protobuf::ProtoParser.new.parse(file)
      end
      message_visitor.create_files rb_file, out_dir, file_create
    end

    def create_rpc(proto_file, proto_dir='.', out_dir='.', file_create=true)
      message_file = "#{out_dir}/#{proto_file.sub(/\.proto$/, '.rb')}"
      out_dir = "#{out_dir}/#{File.dirname proto_file}"
      proto_path = validate_existence proto_file, proto_dir

      rpc_visitor = Protobuf::Visitor::CreateRpcVisitor.new
      File.open proto_path, 'r' do |file|
        rpc_visitor.visit Protobuf::ProtoParser.new.parse(file)
      end
      rpc_visitor.create_files message_file, out_dir, file_create
    end

    def validate_existence(path, base_dir)
      if File.exist? path
      elsif File.exist?(path = "#{base_dir or '.'}/#{path}")
      else
        raise ArgumentError.new("File does not exist: #{path}")
      end
      path
    end
  end
end
