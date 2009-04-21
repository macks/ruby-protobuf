# -*- encoding: utf-8 -*-


Gem::Specification.new do |s|
  s.name = %q{ruby_protobuf}
  s.version = "0.3.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["MATSUYAMA Kengo"]
  s.date = %q{2009-04-21}
  s.description = %q{== DESCRIPTION:  Protocol Buffers for Ruby.  == FEATURES/PROBLEMS:  * Compile .proto file to ruby script * Parse the binary wire format for protocol buffer * Serialize data to the binary wire format for protocol buffer}
  s.email = %q{macksx@gmail.com}
  s.executables = ["mk_parser", "rprotoc"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "bin/mk_parser", "bin/rprotoc", "examples/addressbook.proto", "examples/addressbook.pb.rb", "examples/reading_a_message.rb", "examples/writing_a_message.rb", "lib/protobuf/common/wire_type.rb", "lib/protobuf/compiler/compiler.rb", "lib/protobuf/compiler/nodes.rb", "lib/protobuf/compiler/proto.y", "lib/protobuf/compiler/proto2.ebnf", "lib/protobuf/compiler/proto_parser.rb", "lib/protobuf/compiler/template/rpc_bin.erb", "lib/protobuf/compiler/template/rpc_client.erb", "lib/protobuf/compiler/template/rpc_service.erb", "lib/protobuf/compiler/visitors.rb", "lib/protobuf/descriptor/descriptor.proto", "lib/protobuf/descriptor/descriptor.rb", "lib/protobuf/descriptor/descriptor_builder.rb", "lib/protobuf/descriptor/descriptor_proto.rb", "lib/protobuf/descriptor/enum_descriptor.rb", "lib/protobuf/descriptor/field_descriptor.rb", "lib/protobuf/descriptor/file_descriptor.rb", "lib/protobuf/message/decoder.rb", "lib/protobuf/message/encoder.rb", "lib/protobuf/message/enum.rb", "lib/protobuf/message/extend.rb", "lib/protobuf/message/field.rb", "lib/protobuf/message/message.rb", "lib/protobuf/message/protoable.rb", "lib/protobuf/message/service.rb", "lib/protobuf/rpc/client.rb", "lib/protobuf/rpc/handler.rb", "lib/protobuf/rpc/server.rb", "lib/ruby_protobuf.rb", "test/addressbook.rb", "test/addressbook_base.rb", "test/addressbook_ext.rb", "test/check_unbuild.rb", "test/collision.rb", "test/data/data.bin", "test/data/data_source.py", "test/data/types.bin", "test/data/types_source.py", "test/data/unk.png", "test/ext_collision.rb", "test/ext_range.rb", "test/merge.rb", "test/nested.rb", "test/proto/addressbook.proto", "test/proto/addressbook_base.proto", "test/proto/addressbook_ext.proto", "test/proto/collision.proto", "test/proto/ext_collision.proto", "test/proto/ext_range.proto", "test/proto/merge.proto", "test/proto/nested.proto", "test/proto/rpc.proto", "test/proto/types.proto", "test/test_addressbook.rb", "test/test_compiler.rb", "test/test_descriptor.rb", "test/test_extension.rb", "test/test_message.rb", "test/test_parse.rb", "test/test_ruby_protobuf.rb", "test/test_serialize.rb", "test/test_standard_message.rb", "test/test_types.rb", "test/types.rb", "test/test_optional_field.rb"]
  s.has_rdoc = true
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Protocol Buffers for Ruby}
  s.test_files = ["test/test_descriptor.rb", "test/test_ruby_protobuf.rb", "test/test_message.rb", "test/test_optional_field.rb", "test/test_extension.rb", "test/test_addressbook.rb", "test/test_types.rb", "test/test_standard_message.rb", "test/test_parse.rb", "test/test_compiler.rb", "test/test_serialize.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.12.1"])
    else
      s.add_dependency(%q<hoe>, [">= 1.12.1"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.12.1"])
  end
end
