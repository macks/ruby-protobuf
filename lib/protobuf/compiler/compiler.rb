# This is a quite temporary implementation.
# I'll create a compiler class using Racc.

require 'fileutils'

module Protobuf
  class Compiler
    INDENT_UNIT = '  '

    def self.compile(proto_file, proto_dir='.', out_dir='.', file_create=false)
      self.new.compile proto_file, proto_dir, out_dir, file_create
    end

    def initialize
      @indent_level = 0
      @ret = <<-eos
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'

      eos
    end

    def indent
      INDENT_UNIT * @indent_level
    end

    def puts_with_indent(string)
      #puts "#{indent}#{string}"
      @ret += "#{indent}#{string}\n"
    end
    alias putswi puts_with_indent

    def compile(proto_file, proto_dir='.', out_dir='.', file_create=false)
      rb_file = "#{out_dir}/#{proto_file.sub(/\.proto$/, '.rb')}"
      proto_path = validate_existence proto_file, proto_dir
      File.open proto_path, 'r' do |file|
        file.each_line do |line|
          line.sub!(/^(.*)\/\/.*/, '\1')
          line.strip!
          case line
          when /^package\s+(\w+(\.\w+)?)\s*;$/
            $1.split('.').each do |path|
              putswi "module #{path.capitalize}"
              @indent_level += 1
            end
          when /^import\s+"((?:[^"\\]+|\\.)*)"\s*;$/
            putswi "require '#{required_message_from_proto $1, proto_dir, out_dir}'"
          when /^message\s+(\w+)\s*\{$/
            putswi "class #{$1} < ::Protobuf::Message"
            @extension = false
            @indent_level += 1
          when /^(required|optional|repeated)\s+(\w+(\.\w+)?)\s+(\w+)\s*=\s*(\d+)\s*(\[\s*default\s*=\s*(\w+)\s*\])?\s*;$/
            rule, type, name, tag, default = $1, $2, $4, $5, $7
            if default
              default = default =~ /\d+(\.\d+)/ \
                ? ", {:default => #{default}}" \
                : ", {:default => :#{default}}"
            end
            extension = @extension ? ', :extension => true' : ''
            putswi "#{rule} :#{type}, :#{name}, #{tag}#{default}#{extension}"
          when /^enum\s+(\w+)\s*\{$/
            putswi "class #{$1} < ::Protobuf::Enum"
            @indent_level += 1
          when /^(\w+)\s*=\s*(\w+)\s*;$/
            putswi "#{$1} = #{$2}"
          when /^extensions\s+(\w+)\s+to\s+(\w+)\s*;/
            low, high = $1, $2
            low = '::Protobuf::Extend.MIN' if low == 'min'
            high = '::Protobuf::Extend.MAX' if high == 'max'
            putswi "extensions #{low}..#{high}"
          when /^extend\s+(\w+)\s*\{/
            putswi "class #{$1} < ::Protobuf::Message"
            @extension = true
            @indent_level += 1
          when /^service\s+(\w+)\s*\{/
            putswi "class #{$1} < ::Protobuf::Service"
            @indent_level += 1
          when /^rpc\s+(\w+)\s+\(\s*(\w+)\s*\)\s+returns\s+\(\s*(\w+)\s*\)\s*;/
            putswi "rpc :#{$1} => :#{$2}, :#{$3} => :#{$4}"
          when /^option\s+(\w+)\s*=\s*(.+)\s*;/
            putswi "::Protobuf::OPTIONS[:#{$1}] = :#{$2}"
          when /^\}\s*;?$/
            @indent_level -= 1
            putswi "end"
          when ''
            putswi ''
          end
        end
        while 0 < @indent_level 
          @indent_level -= 1
          putswi "end"
        end
      end
      if file_create
        puts "#{rb_file} writing..."
        FileUtils.mkpath File.dirname(rb_file)
        File.open(rb_file, 'w') {|f| f.write @ret}
      end
      @ret
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
