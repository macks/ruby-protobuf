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
        define_accessor
      end

      def ready?; true end

      def initialized?(message)
        case rule
        when :required
          return false if message[name].nil?
          return false if is_a?(Protobuf::Field::MessageField) and not message[name].initialized?
        when :repeated
          return message[name].all? {|msg|
            (not is_a?(Protobuf::Field::MessageField)) or msg.initialized?
          }
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

      private

      def define_accessor
        define_getter
        if rule == :repeated
          define_array_setter
        else
          define_setter
        end
      end

      def define_getter
        field = self
        @message_class.class_eval do
          define_method(field.name) do
            if @values.has_key?(field.name)
              @values[field.name]
            else
              field.default_value
            end
          end
        end
      end

      def define_setter
        field = self
        @message_class.class_eval do
          define_method("#{field.name}=") do |val|
            if val.nil?
              @values.delete(field.name)
            elsif field.acceptable? val
              @values[field.name] = val
            end
          end
        end
      end

      def define_array_setter
        field = self
        @message_class.class_eval do
          define_method("#{field.name}=") do |val|
            @values[field.name].replace(val)
          end
        end
      end

      public

      # encoder/decoder related methods

      def set(message_instance, bytes)
        value = decode(bytes)
        if repeated?
          message_instance.send(name) << value
        else
          message_instance.send("#{name}=", value)
        end
      end

      def get(value)
        encode(value)
      end

      def decode(bytes)
        raise NotImplementedError.new("#{self.class.name}\#decode")
      end
      private :decode

      def encode(value)
        raise NotImplementedError.new("#{self.class.name}\#encode")
      end
      private :encode

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

      # utility methods

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
            raise TypeError.new(type.inspect)
          end
        field_class.new @message_class, @rule, type, @name, @tag, @opts
      end

      def typename_to_class(message_class, type)
        suffix = type.to_s.split('::')
        modules = message_class.to_s.split('::')
        args = (Object.method(:const_defined?).arity == 1) ? [] : [nil, false]
        while
          mod = modules.empty? ? Object : eval(modules.join('::'))
          mod = suffix.inject(mod) {|m, s|
            args[0] = s
            m and m.const_defined?(*args) and m.const_get(s)
          }
          break if mod
          raise NameError.new("type not found: #{type}", type) if modules.empty?
          modules.pop
        end
        mod
      end
    end

    class FieldArray < Array
      def initialize(field)
        @field = field
      end

      def []=(nth, val)
        super(normalize(val))
      end

      def <<(val)
        super(normalize(val))
      end

      def push(val)
        super(normalize(val))
      end

      def unshift(val)
        super(normalize(val))
      end

      def replace(val)
        raise TypeError unless val.is_a?(Array)
        val = val.map {|v| normalize(v)}
        super(val)
      end

      def to_s
        "[#{@field.name}]"
      end

      private

      def normalize(val)
        raise TypeError unless @field.acceptable?(val)
        if @field.is_a?(MessageField) && val.is_a?(Hash)
          @field.type.new(val)
        else
          val
        end
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

      def decode(bytes)
        bytes.pack('C*')
      end

      def encode(value)
        value = value.dup
        value.force_encoding('ASCII-8BIT') if value.respond_to?(:force_encoding)
        string_size = VarintField.encode(value.size)
        string_size << value
      end
    end

    class StringField < BytesField
      def decode(bytes)
        message = bytes.pack('C*')
        message.force_encoding('UTF-8') if message.respond_to?(:force_encoding)
        message
      end
    end

    class VarintField < BaseField
      INT32_MAX  =  2**31 - 1
      INT32_MIN  = -2**31
      INT64_MAX  =  2**63 - 1
      INT64_MIN  = -2**63
      UINT32_MAX =  2**32 - 1
      UINT64_MAX =  2**64 - 1

      class <<self
        def default; 0 end

        def decode(bytes)
          value = 0
          bytes.each_with_index do |byte, index|
            value |= byte << (7 * index)
          end
          value
        end

        def encode(value)
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
      end

      def wire_type
        Protobuf::WireType::VARINT
      end

      def decode(bytes)
        self.class.decode(bytes)
      end

      def encode(value)
        self.class.encode(value)
      end

      def acceptable?(val)
        raise TypeError.new(val.class.name) unless val.is_a? Integer
        raise RangeError.new(val) if val < min or max < val
        true
      end
    end

    # Base class for int32 and int64
    class IntegerField < VarintField
      def encode(value)
        # original Google's library uses 64bits integer for negative value
        VarintField.encode(value & 0xffff_ffff_ffff_ffff)
      end

      def decode(bytes)
        value  = VarintField.decode(bytes)
        value -= 0x1_0000_0000_0000_0000 if (value & 0x8000_0000_0000_0000).nonzero?
        value
      end
    end

    class Int32Field < IntegerField
      def self.max; INT32_MAX; end
      def self.min; INT32_MIN; end
    end

    class Int64Field < IntegerField
      def self.max; INT64_MAX; end
      def self.min; INT64_MIN; end
    end

    class Uint32Field < VarintField
      def self.max; UINT32_MAX; end
      def self.min; 0; end
    end

    class Uint64Field < VarintField
      def self.max; UINT64_MAX; end
      def self.min; 0; end
    end

    # Base class for sint32 and sint64
    class SignedIntegerField < VarintField
      def decode(bytes)
        value = VarintField.decode(bytes)
        if (value & 1).zero?
          value >> 1   # positive value
        else
          ~value >> 1  # negative value
        end
      end

      def encode(value)
        if value >= 0
          VarintField.encode(value << 1)
        else
          VarintField.encode(~(value << 1))
        end
      end
    end

    class Sint32Field < SignedIntegerField
      def self.max; INT32_MAX; end
      def self.min; INT32_MIN; end
    end

    class Sint64Field < SignedIntegerField
      def self.max; INT64_MAX; end
      def self.min; INT64_MIN; end
    end

    class FloatField < BaseField
      def self.default; 0.0; end
      def self.max;  1.0/0; end
      def self.min; -1.0/0; end

      def wire_type
        Protobuf::WireType::FIXED32
      end

      def decode(bytes)
        bytes.unpack('e').first
      end

      def encode(value)
        [value].pack('e')
      end

      def acceptable?(val)
        raise TypeError.new(val.class.name) unless val.is_a? Numeric
        raise RangeError.new(val) if val < min or max < val
        true
      end
    end

    class DoubleField < FloatField
      def wire_type
        Protobuf::WireType::FIXED64
      end

      def decode(bytes)
        bytes.unpack('E').first
      end

      def encode(value)
        [value].pack('E')
      end
    end

    class Fixed32Field < Uint32Field
      def wire_type
        Protobuf::WireType::FIXED32
      end

      def decode(bytes)
        bytes.unpack('V').first
      end

      def encode(value)
        [value].pack('V')
      end
    end

    class Fixed64Field < Uint64Field
      def wire_type
        Protobuf::WireType::FIXED64
      end

      def decode(bytes)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        values = bytes.unpack('VV')
        values[0] + (values[1] << 32)
      end

      def encode(value)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        [value & 0xffff_ffff, value >> 32].pack('VV')
      end
    end

    class Sfixed32Field < Int32Field
      def wire_type
        Protobuf::WireType::FIXED32
      end

      def decode(bytes)
        value  = bytes.unpack('V').first
        value -= 0x1_0000_0000 if (value & 0x8000_0000).nonzero?
        value
      end

      def encode(value)
        [value].pack('V')
      end
    end

    class Sfixed64Field < Int64Field
      def wire_type
        Protobuf::WireType::FIXED64
      end

      def decode(bytes)
        # we don't use 'Q' for pack/unpack. 'Q' is machine-dependent.
        values = bytes.unpack('VV')
        value  = values[0] + (values[1] << 32)
        value -= 0x1_0000_0000_0000_0000 if (value & 0x8000_0000_0000_0000).nonzero?
        value
      end

      def encode(value)
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

      def decode(bytes)
        bytes.first == 1
      end

      def encode(value)
        [value ? 1 : 0].pack('C')
      end
    end

    class MessageField < BaseField
      class <<self
        def default; nil end
      end

      def define_setter
        field = self
        @message_class.class_eval do
          define_method("#{field.name}=") do |val|
            case val
            when nil
              @values.delete(field.name)
            when Hash
              @values[field.name] = field.type.new(val)
            when field.type
              @values[field.name] = val
            else
              raise TypeError
            end
          end
        end
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
        raise TypeError unless val.instance_of?(type) or val.instance_of?(Hash)
        true
      end

      def decode(bytes)
        message = type.new
        message.parse_from_string bytes.pack('C*') # TODO
        message
      end

      def encode(value)
        bytes = value.serialize_to_string
        string_size = VarintField.encode bytes.size
        string_size << bytes
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
