module Protobuf
  class FileDescriptor
    class <<self
      def proto_type
        'Google::Protobuf::FileDescriptorProto'
      end

      def build(proto, opt={})
        mod = Object
        if package = proto.package and not package.empty?
          module_names = package.split '::'
          module_names.each do |module_name|
            mod = mod.const_set module_name, Module.new
          end
        end
        proto.message_type.each do |message_proto|
          Protobuf::Message.build message_proto, :module => mod
        end
        proto.enum_type.each do |enum_proto|
          Protobuf::Enum.build enum_proto, :module => mod
        end
      end

      def unbuild(descriptors)
        descriptors = [descriptors] unless descriptors.is_a? Array
        proto = Google::Protobuf::FileDescriptorProto.new
        proto.package = descriptors.first.to_s.split('::')[0..-2].join('::') if descriptors.first.to_s =~ /::/
        descriptors.each do |descriptor|
          #descriptor.unbuild proto
        end
        proto
      end
    end
  end
end

