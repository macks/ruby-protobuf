require 'rubygems'
require 'rake'
require 'protobuf/compiler/compiler'

module Protobuf
  class GenerateTask < Rake::TaskLib
    def initialize(*proto_paths, &block)
      init(proto_paths)

      define(&block)
    end

    def init(*proto_paths)
      @proto_paths = Rake::FileList.new(proto_paths)
    end

    def define
      @proto_paths.each do |protobuf|
        ruby_protobuf = File.join("lib", File.basename(protobuf, File.extname(protobuf)) + ".pb.rb")

        compile_task = file ruby_protobuf => protobuf do
          Protobuf::Compiler.compile(protobuf, File.dirname(protobuf), File.dirname(ruby_protobuf))
        end

        task :protobuf => [ compile_task ]

        yield ruby_protobuf if block_given?
      end
    end
  end
end
