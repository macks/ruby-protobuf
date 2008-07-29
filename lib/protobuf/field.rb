require 'protobuf/wire_type'

module Protobuf
  module Field
    def self.build(message_class, rule, type, name, tag, opts={})
      Base.build message_class, rule, type, name, tag, opts
    end

    class InvalidRuleError < StandardError; end

    class Base
      class <<self
        def build(message_class, rule, type, name, tag, opts={})
          field_class = nil
          begin
            field_class = eval "Protobuf::Field::#{type.to_s.capitalize}Field"
          rescue NameError
            type = typename_to_class message_class, type
            field_class =
              if type.superclass == Protobuf::Enum
                Protobuf::Field::Enum
              elsif type.superclass == Protobuf::Message
                Protobuf::Field::Message
              else
                raise $!
              end
          end
          field_class.new message_class, rule, type, name, tag, opts
        end

        def typename_to_class(message_class, type)
          modules = message_class.to_s.split('::')
          while
            begin
              type = eval((modules | [type.to_s]).join('::'))
              break
            rescue NameError
              modules.empty? ? raise($!) : modules.pop
            end
          end
          type
        end
      end

      attr_accessor :message_class, :rule, :type, :name, :tag, :default

      def initialize(message_class, rule, type, name, tag, opts={})
        @message_class, @rule, @type, @name, @tag, @default = 
          message_class, rule, type, name, tag, opts[:default]
        @error_message = 'Type invalid'
      end

      def default_value
        case rule
        when :repeated
          FieldArray.new self
        when :required, :optional
          typed_default_value default
        else
          raise InvalidRuleError
        end
      end

      def typed_default_value(default=nil)
        default
      end

      def define_accessor(message_instance)
        message_instance.instance_variable_set "@#{name}", default_value
        define_getter message_instance
        define_setter message_instance unless rule == :repeated
      end

      def define_getter(message_instance)
        message_instance.instance_eval %Q{
          def #{name}
            @#{name}
          end
        }
      end

      def define_setter(message_instance)
        message_instance.instance_eval %Q{
          def #{name}=(val)
            field = get_field_by_name #{name.inspect}
            if field.acceptable? val
              @#{name} = val
            else
              raise TypeError.new(field.error_message)
            end
          end
        }
      end

      def set(message_instance, bytes)
        if repeated?
          set_array message_instance, bytes
        else
          set_bytes message_instance, bytes
        end
      end

      def set_array(message_instance, bytes)
        raise NotImplementedError
      end

      def set_bytes(message_instance, bytes)
        raise NotImplementedError
      end

      def get(value)
        get_bytes value
      end

      def get_bytes(value)
        raise NotImplementedError
      end

      def merge(message_instance, bytes)
        if repeated?
          merge_array method_instance, bytes
        else
          merge_value method_instance, bytes
        end
      end

      def merge_array(message_instance, bytes)
        raise NotImplementedError
      end

      def merge_value(message_instance, bytes)
        raise NotImplementedError
      end

      def repeated?; rule == :repeated end
      def required?; rule == :required end
      def optional?; rule == :optional end

      def acceptable?(val)
        true
      end

      def error_message
        @error_message
      end

      def to_s
        "#{rule} #{type} #{name} = #{tag} #{default ? "[default=#{default}]" : ''}"
      end
    end

    class FieldArray < Array
      def initialize(field)
        @field = field
      end

      def []=(nth, val)
        if @field.acceptable? val
          super
        else
          raise TypeError
        end
      end

      def <<(val)
        if @field.acceptable? val
          super
        else
          raise TypeError
        end
      end

      def push(val)
        if @field.acceptable? val
          super
        else
          raise TypeError
        end
      end

      def unshift(val)
        if @field.acceptable? val
          super
        else
          raise TypeError
        end
      end

      def to_s
        "[#{@field.name}]"
      end
    end

    class StringField < Base
      def wire_type
        Protobuf::WireType::LENGTH_DELIMITED
      end

      def typed_default_value(default=nil)
        default or ''
      end

      def acceptable?(val)
        val.instance_of? String
      end

      def set_bytes(method_instance, bytes)
        method_instance.send("#{name}=", bytes.to_string)
      end

      def get_bytes(value)
        bytes = value.unpack('U*')
        string_size = Varint.get_bytes bytes.size
        string_size + bytes
      end
    end
    
    class BytesField < Base
      def wire_type
        Protobuf::WireType::VARINT
      end

      def typed_default_value(default=nil)
        default or ''
      end
    end

    class Varint < Base
      def wire_type
        Protobuf::WireType::VARINT
      end

      def typed_default_value(default=nil)
        default or 0
      end
 
      def set_bytes(method_instance, bytes)
        method_instance.send("#{name}=", bytes.to_varint)
      end

      def self.get_bytes(value)
        # TODO should refactor using unpack('w*')
        bytes = []
        until value == 0
          byte = 0
          7.times do |i|
            byte |= (value & 1) << i
            value >>= 1
          end
          byte |= 0b10000000
          bytes << byte
        end
        #bytes[0] &= 0b01111111
        #bytes
        bytes[bytes.size - 1] &= 0b01111111
        bytes
      end

      def get_bytes(value)
        self.class.get_bytes value
      end
    end
    
    class Int32Field < Varint
    end
    
    class Int64Field < Varint
    end
    
    class Uint32Field < Varint
    end
    
    class Uint64Field < Varint
    end
    
    class Sint32Field < Varint
    end
    
    class Sint64Field < Varint
    end
    
    class DoubleField < Varint
      def wire_type
        Protobuf::WireType::FIXED64
      end
    end
    
    class FloatField < Varint
      def wire_type
        Protobuf::WireType::FIXED32
      end
    end
    
    class Fixed32Field < Varint
      def wire_type
        Protobuf::WireType::FIXED32
      end
    end
    
    class Fixed64Field < Varint
      def wire_type
        Protobuf::WireType::FIXED64
      end
    end
    
    class Sfinxed32Field < Varint
      def wire_type
        Protobuf::WireType::FIXED32
      end
    end
    
    class Sfixed64Field < Varint
      def wire_type
        Protobuf::WireType::FIXED64
      end
    end
    
    class BoolField < Base
      def typed_default_value(default=nil)
        default or false
      end

      def acceptable?(val)
        [TrueClass, FalseClass].include? val.class
      end
    end
    
    class Message < Base
      def wire_type
        Protobuf::WireType::LENGTH_DELIMITED
      end

      def typed_default_value(default=nil)
        if default.is_a? Symbol
          type.module_eval default.to_s
        else
          default
        end
      end

      def acceptable?(val)
        val.instance_of? type
      end
 
      def set_bytes(method_instance, bytes)
        message = type.new
        #message.parse_from bytes
        message.parse_from_string bytes.to_string # TODO
        method_instance.send("#{name}=", message)
      end
 
      def set_array(method_instance, bytes)
        message = type.new
        #message.parse_from bytes
        message.parse_from_string bytes.to_string
        arr = method_instance.send name
        arr << message
      end

      def get_bytes(value)
        stringio = StringIO.new ''
        value.serialize_to stringio
        bytes = stringio.string.unpack 'C*'
        string_size = Varint.get_bytes bytes.size
        string_size + bytes
        #bytes + string_size
      end
    end

    class Enum < Varint
      def acceptable?(val)
        type.valid_tag? val
      end
    end
  end
end
