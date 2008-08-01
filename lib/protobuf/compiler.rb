# This is a quite temporary implementation.
# I'll create a compiler class using Racc.

module Protobuf
  class Compiler
    INDENT_UNIT = '  '

    def self.compile(filename)
      self.new.compile filename
    end

    def initialize
      @indent_level = 0
      @ret = <<-eos
require 'protobuf/message'
require 'protobuf/enum'
require 'protobuf/service'
require 'protobuf/extend'

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

    def compile(filename)
      File.open filename, 'r' do |file|
        file.each_line do |line|
          line.sub!(/^(.*)\/\/.*/, '\1')
          line.strip!
          case line
          when /^package\s+(\w+(\.\w+)?)\s*;$/
            $1.split('.').each do |path|
              putswi "module #{path.capitalize}"
              @indent_level += 1
            end
          when /^message\s+(\w+)\s*\{$/
            putswi "class #{$1} < ::Protobuf::Message"
            @indent_level += 1
          when /^(required|optional|repeated)\s+(\w+(\.\w+)?)\s+(\w+)\s*=\s*(\d+)\s*(\[\s*default\s*=\s*(\w+)\s*\])?\s*;$/
            rule, type, name, tag, default = $1, $2, $4, $5, $7
            if default
              default = default =~ /\d+(\.\d+)/ \
                ? ", {:default => #{default}}" \
                : ", {:default => :#{default}}"
            end
            putswi "#{rule} :#{type}, :#{name}, #{tag}#{default}"
          when /^enum\s+(\w+)\s*\{$/
            putswi "class #{$1} < ::Protobuf::Enum"
            @indent_level += 1
          when /^(\w+)\s*=\s*(\w+)\s*;$/
            putswi "#{$1} = #{$2}"
          when /^extensions\s+(\w+)\s+to\s+(\w+)\s*;/
            low, high = $1, $2
            low = '::Protobuf::Extend.MIN' if low == 'min'
            high = '::Protobuf::Extend.MAX' if high == 'max'
            putswi "extensions #{min}..#{max}"
          when /^extend\s+(\w+)\s*\{/
            putswi "class #{$1} < ::Protobuf::Extend"
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
      @ret
    end
  end
end
