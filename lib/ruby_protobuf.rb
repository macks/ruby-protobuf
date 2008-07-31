require 'protobuf/compiler'

class RubyProtobuf
  VERSION = '0.0.1'

  def start(proto_file, options)
    unless File.exist?(proto_file)
      if File.exist? "#{proto_file}.proto"
        proto_file = "#{proto_file}.proto"
      else
        raise ArgumentError.new("#{proto_file} does not exist.")
      end
    end
    rb_filename = File.basename proto_file
    rb_filename += '.rb' unless rb_filename.sub!(/.\w+$/, '.rb')
    rb_filepath = "#{options[:out] || '.'}/#{rb_filename}"
    puts "#{rb_filepath} writting..."
    File.open(rb_filepath, 'w') do |f|
      f.write Protobuf::Compiler.compile(proto_file)
    end
  end
end