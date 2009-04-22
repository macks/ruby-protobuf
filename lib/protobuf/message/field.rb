require 'protobuf/common/wire_type'
require 'protobuf/descriptor/field_descriptor'

module Protobuf
  module Field
    def self.build(message_class, rule, type, name, tag, opts={})
      field_class = 
        if [:double, :float, :int32, :int64, :uint32, :uint64, 
          :sint32, :sint64, :fixed32, :fixed64, :sfixed32, :sfixed64, 
          :bool, :string, :bytes].include? type
          eval "Protobuf::Field::#{type.to_s.capitalize}Field"
        else
          Protobuf::Field::FieldProxy
        end
      field_class.new message_class, rule, type, name, tag, opts
    end

    class InvalidRuleError < StandardError; end

    class BaseField
      class <<self
        def descriptor
          @descriptor ||= Protobuf::Descriptor::FieldDescriptor.new
        end

        def default; nil end
      end

      attr_accessor :message_class, :rule, :type, :name, :tag, :default

      def descriptor
        @descriptor ||= Protobuf::Descriptor::FieldDescriptor.new self
      end

      def initialize(message_class, rule, type, name, tag, opts={})
        @message_class, @rule, @type, @name, @tag, @default, @extension = 
          message_class, rule, type, name, tag, opts[:default], opts[:extension]
        @error_message = 'Type invalid'
      end

      def ready?; true end

      def initialized?(message)
        case rule
        when :required
          return false if message[name].nil?
          return false if is_a?(Protobuf::Field::MessageField) and not message[name].initialized?
        when :repeated
          return message[name].inject(true) do |result, msg|
            result and msg.initialized?
          end
        when :optional
          return false if message[name] and is_a?(Protobuf::Field::MessageField) and not message[name].initialized?
        end
        true
      end

      def clear(message)
        if repeated?
          message[name].clear
        else
          message.instance_variable_get(:@values).delete(name)
        end
      end

      def default_value
        case rule
        when :repeated
          FieldArray.new self
        when :required
          nil
        when :optional
          typed_default_value default
        else
          raise InvalidRuleError
        end
      end

      def typed_default_value(default=nil)
        default or self.class.default
      end

      def define_accessor(message_instance)
        message_instance.instance_variable_get(:@values)[name] = default_value if rule == :repeated
        define_getter message_instance
        define_setter message_instance unless rule == :repeated
      end

      def define_getter(message_instance)
        field = self
        metaclass = (class << message_instance; self; end)
        metaclass.class_eval do
          define_method(field.name) do
            @values[field.name] or field.default_value
          end
        end
      end

      def define_setter(message_instance)
        field = self
        metaclass = (class << message_instance; self; end)
        metaclass.class_eval do
          define_method("#{field.name}=") do |val|
            if val.nil?
              @values.delete(field.name)
            elsif field.acceptable? val
              @values[field.name] = val
            end
          end
        end
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

      def merge(message_instance, value)
        if repeated?
          merge_array message_instance, value
        else
          merge_value message_instance, value
        end
      end

      def merge_array(message_instance, value)
        message_instance[tag].concat value 
      end

      def merge_value(message_instance, value)
        message_instance[tag] = value
      end

      def repeated?; rule == :repeated end
      def required?; rule == :required end
      def optional?; rule == :optional end

      def max; self.class.max end
      def min; self.class.min end

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

    class FieldProxy
      def initialize(message_class, rule, type, name, tag, opts={})
        @message_class, @rule, @type, @name, @tag, @opts =
          message_class, rule, type, name, tag, opts
      end

      def ready?; false end

      def setup
        type = typename_to_class @message_class, @type
        field_class =
          if type.superclass == Protobuf::Enum
            Protobuf::Field::EnumField
          elsif type.superclass == Protobuf::Message
            Protobuf::Field::MessageField
          else
            raise $!
          end
        field_class.new @message_class, @rule, type, @name, @tag, @opts
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
=begin
      def typename_to_class(message_class, type)
        suffix = type.to_s.split('::')
        modules = message_class.to_s.split('::')
        while
          mod = modules.empty? ? Object : eval(modules.join('::'))
          suffix.each do |s|
            if mod.const_defined?(s)
              mod = mod.const_get(s)
            else
              mod = nil
              break
            end
          end
          break if mod
          raise NameError.new("type not found: #{type}", type) if modules.empty?
          modules.pop
        end
        mod
      end
=end
    end

    class FieldArray < Array
      def initialize(field)
        @field = field
      end

      def []=(nth, val)
        if @field.acceptable? val
          super
        end
      end

      def <<(val)
        if @field.acceptable? val
          super
        end
      end

      def push(val)
        if @field.acceptable? val
          super
        end
      end

      def unshift(val)
        if @field.acceptable? val
          super
        end
      end

      def to_s
        "[#{@field.name}]"
      end
    end

    class BytesField < BaseField
      class <<self
        def default; '' end
      end

      def wire_type
        Protobuf::WireType::LENGTH_DELIMITED
      end

      def acceptable?(val)
        raise TypeError unless val.instance_of? String
        true
      end

      def set_bytes(message_instance, bytes)
        message_instance.send("#{name}=", bytes.pack('C*'))
      end
 
      def set_array(message_instance, bytes)
        message = bytes.pack('C*')
        arr = message_instance.send name
        arr << message
      end

      def get_bytes(value)
        value = value.dup
        value.force_encoding('ASCII-8BIT') if value.respond_to?(:force_encoding)
        string_size = VarintField.get_bytes(value.size)
        string_size << value
      end
    end

    class StringField < BytesField
      def set_bytes(message_instance, bytes)
        message = bytes.pack('C*')
        message.force_encoding('UTF-8') if message.respond_to?(:force_encoding)
        message_instance.send("#{name}=", message)
      end
 
      def set_array(message_instance, bytes)
        message = bytes.pack('C*')
        message.force_encoding('UTF-8') if message.respond_to?(:force_encoding)
        arr = message_instance.send name
        arr << message
      end
    end

    class VarintField < BaseField
      INT32_MAX  =  2**31 - 1
      INT32_MIN  = -2**31
      INT64_MAX  =  2**63 - 1
      INT64_MIN  = -2**63 - 1
      UINT32_MAX =  2**32 - 1
      UINT64_MAX =  2**64 - 1

      class <<self
        def default; 0 end
      end

      def wire_type
        Protobuf::WireType::VARINT
      end

      def self.decode_bytes(bytes)
        value = 0
        bytes.each_with_index do |byte, index|
          value |= byte << (7 * index)
        end
        value
      end
 
      def set_bytes(message_instance, bytes)
        value = self.class.decode_bytes(bytes)
        message_instance.send("#{name}=", value)
      end

      def self.get_bytes(value)
        raise RangeError.new(value) if value < 0
        return [value].pack('C') if value < 128
        bytes = []
        until value == 0
          bytes << (0x80 | (value & 0x7f))
          value >>= 7
        end
        bytes[-1] &= 0x7f
        bytes.pack('C*')
      end

      def get_bytes(value)
        self.class.get_bytes value
      end

      def acceptable?(val)
        raise TypeError.new(val.class.name) unless val.is_a? Integer
        raise RangeError.new(val) if val < min or max < val
        true
      end
    end
    
    class Int32Field < VarintField
      def self.max; INT32_MAX; end
      def self.min; INT32_MIN; end

      def get_bytes(value)
        # original Google's library uses 64bits integer for negative value
        self.class.get_bytes(value & 0xffff_ffff_ffff_ffff)
      end
 
      def set_bytes(message_instance, bytes)
        value  = self.class.decode_bytes(bytes)
        value -= 0x1_0000_0000_0000_0000 if (value & 0x8000_0000_0000_0000).nonzero?
        message_instance.send("#{name}=", value)
      end
    end
    
    class Int64Field < VarintField
      def self.max; INT64_MAX; end
      def self.min; INT64_MIN; end

      def get_bytes(value)
        self.class.get_bytes(value & 0xffff_ffff_ffff_ffff)
      end
 
      def set_bytes(message_instance, bytes)
        value  = self.class.decode_bytes(bytes)
        value -= 0x1_0000_0000_0000_0000 if (value & 0x8000_0000_0000_0000).nonzero?
        message_instance.send("#{name}=", value)
      end
    end
    
    class Uint32Field < VarintField
      def self.max; UINT32_MAX; end
      def self.min; 0; end
    end
    
    class Uint64Field < VarintField
      def self.max; UINT64_MAX; end
      def self.min; 0; end
    end
    
    class Sint32Field < VarintField
      def self.max; INT32_MAX; end
      def self.min; INT32_MIN; end
 
      def set_bytes(message_instance, bytes)
        value = self.class.decode_bytes(bytes)
        if (value & 1).zero?
          value >>= 1   # positive value
        else
          value = -(value >> 1) - 1  # negative value
        end
        message_instance.send("#{name}=", value)
      end

      def get_bytes(value)
        if value >= 0
          self.class.get_bytes(value << 1)
        else
          self.class.get_bytes((value << 1) & 0xffff_ffff ^ 0xffff_ffff)
        end
      end
    end
    
    class Sint64Field < VarintField
      def self.max; INT64_MAX; end
      def self.min; INT64_MIN; end
 
      def set_bytes(message_instance, bytes)
        value = self.class.decode_bytes(bytes)
        if (value & 1).zero?
          value >>= 1   # positive value
        else
          value = -(value >> 1) - 1  # negative value
        end
        message_instance.send("#{name}=", value)
      end

      def get_bytes(value)
        if value >= 0
          self.class.get_bytes(value << 1)
        else
          self.class.get_bytes((value << 1) & 0xffff_ffff_ffff_ffff ^ 0xffff_ffff_ffff_ffff)
        end
      end
    end
    
    class DoubleField < VarintField
      def wire_type
        Protobuf::WireType::FIXED64
      end
 
      def self.max
        1.0/0.0
      end

      def self.min
        -1.0/0.0
      end
 
      def set_bytes(message_instance, bytes)
        message_instance.send("#{name}=", bytes.unpack('E').first)
      end

      def get_bytes(value)
        [value].pack('E')
      end

      def acceptable?(val)
        raise TypeError.new(val.class.name) unless val.is_a? Numeric
        raise RangeError.new(val) if val < min or max < val
        true
      end
    end
    
    class FloatField < VarintField
      def wire_type
        Protobuf::WireType::FIXED32
      end
 
      def self.max
        1.0/0
      end

      def self.min
        -1.0/0
      end
 
      def set_bytes(message_instance, bytes)
        message_instance.send("#{name}=", bytes.unpack('e').first)
      end

      def get_bytes(value)
        [value].pack('e')
      end
 
      def acceptable?(val)
        raise TypeError unless val.is_a? Numeric
        raise RangeError if val < min or max < val
        true
      end
    end
    
    class Fixed32Field < VarintField
      def wire_type
        Protobuf::WireType::FIXED32
      end

      def self.max
        UINT32_MAX
      end

      def self.min
        0
      end
 
      def set_bytes(message_instance, bytes)
        message_instance.send("#{name}=", bytes.unpack('V').first)
      end

      def get_bytes(value)
        [value].pack('V')
      end
    end
    
    class Fixed64Field < VarintField
      def wire_type
        Protobuf::WireType::FIXED64
      end

      def self.max
        UINT64_MAX
      end

      def self.min
        0
      end
 
      def set_bytes(message_instance, bytes)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        values = bytes.unpack('VV')
        value = values[0] + (values[1] << 32)
        message_instance.send("#{name}=", value)
      end

      def get_bytes(value)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        [value & 0xffff_ffff, value >> 32].pack('VV')
      end
    end

    class Sfixed32Field < VarintField
      def wire_type
        Protobuf::WireType::FIXED32
      end

      def self.max
        INT32_MAX
      end

      def self.min
        INT32_MIN
      end
 
      def set_bytes(message_instance, bytes)
        value  = bytes.unpack('V').first
        value -= 0x1_0000_0000 if (value & 0x8000_0000).nonzero?
        message_instance.send("#{name}=", value)
      end

      def get_bytes(value)
        [value].pack('V')
      end
    end
    
    class Sfixed64Field < VarintField
      def wire_type
        Protobuf::WireType::FIXED64
      end

      def self.max
        INT64_MAX
      end

      def self.min
        INT64_MIN
      end
 
      def set_bytes(message_instance, bytes)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        values = bytes.unpack('VV')
        value  = values[0] + (values[1] << 32)
        value -= 0x1_0000_0000_0000_0000 if (value & 0x8000_0000_0000_0000).nonzero?
        message_instance.send("#{name}=", value)
      end

      def get_bytes(value)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        [value & 0xffff_ffff, value >> 32].pack('VV')
      end
    end
    
    class BoolField < VarintField
      class <<self
        def default; false end
      end

      def acceptable?(val)
        raise TypeError unless [TrueClass, FalseClass].include? val.class
        true
      end
 
      def set_bytes(message_instance, bytes)
        message_instance.send("#{name}=", bytes.first == 1)
      end

      def get_bytes(value)
        [value ? 1 : 0].pack('C')
      end
    end
    
    class MessageField < BaseField
      class <<self
        def default; nil end
      end

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
        raise TypeError unless val.instance_of? type
        true
      end
 
      def set_bytes(message_instance, bytes)
        message = type.new
        message.parse_from_string bytes.pack('C*') # TODO
        message_instance.send("#{name}=", message)
      end
 
      def set_array(message_instance, bytes)
        message = type.new
        message.parse_from_string bytes.pack('C*')
        arr = message_instance.send name
        arr << message
      end

      def get_bytes(value)
        stringio = StringIO.new ''
        value.serialize_to stringio
        bytes = stringio.string.unpack 'C*'
        string_size = VarintField.get_bytes bytes.size
        string_size + bytes.pack('C*')
      end

      def merge_value(message_instance, value)
        message_instance[tag].merge_from value
      end
    end

    class EnumField < VarintField
      def default
        if @default.is_a?(Symbol)
          type.const_get @default
        else
          @default
        end
      end

      def acceptable?(val)
        raise TypeError unless type.valid_tag? val
        true
      end
    end
  end
end
