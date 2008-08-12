require 'protobuf/compiler/proto_parser'
require 'protobuf/compiler/nodes'

module Protobuf
  class Compiler
    def self.compile(proto_file, proto_dir='.', out_dir='.', file_create=true)
      self.new.compile proto_file, proto_dir, out_dir, file_create
    end

    def compile(proto_file, proto_dir='.', out_dir='.', file_create=true)
      rb_file = "#{out_dir}/#{proto_file.sub(/\.proto$/, '.rb')}"
      proto_path = validate_existence proto_file, proto_dir
      visitor = Protobuf::Node::ToRubyVisitor.new
      File.open proto_path, 'r' do |file|
        visitor.visit Protobuf::ProtoParser.new.parse(file)
      end
      if file_create
        puts "#{rb_file} writing..."
        FileUtils.mkpath File.dirname(rb_file)
        File.open(rb_file, 'w') {|f| f.write visitor.to_s}
      end
    end

    def validate_existence(path, base_dir)
      if File.exist? path
      elsif File.exist?(path = "#{base_dir or '.'}/#{path}")
      else
        raise ArgumentError.new("File does not exist: #{path}")
      end
      path
    end

    def required_message_from_proto(proto_file, proto_dir, out_dir)
      rb_path = proto_file.sub(/\.proto$/, '.rb')
      proto_dir ||= '.'
      out_dir ||= '.'
      unless File.exist?("#{out_dir}/#{rb_path}")
        Compiler.compile proto_file, proto_dir, out_dir
      end
      rb_path
    end
  end
end

=begin
parser = Protobuf::ProtoParser.new
File.open ARGV[0], 'r' do |f|
  result = parser.parse(f)
  puts Protobuf::Node::ToRubyVisitor.new.visit(result).to_s
end
=end
