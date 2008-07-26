module Protobuf
  module Field
    class TypedArray < Array
      def initialize(klass)
        @klass = klass
      end

      def check_type?(val)
        raise TypeError.new("#{val.class.name} should be an instance of #{@klass.name}") unless val.is_a? @klass
      end

      def []=(nth, val)
        super if check_type? val
      end

      def <<(val)
        super if check_type? val
      end
    end

    class BaseField
      STRING_TYPES = [:string, :bytes]
      NUMERIC_TYPES = [:int32, :int64, :uint32, :uint64, :sint32, :sint64, :double, :float, :fixed32, :fixed64, :sfinxed32, :sfixed64]
      BOOLEAN_TYPES = [:bool]

      attr_accessor :rule, :type, :name, :tag

      class <<self
        def build(message_class, rule, type, name, tag, opts={})
          field_class_for(type).new message_class, rule, type, name, tag, opts
        end

        def field_class_for(type)
          begin
            eval "Protobuf::Field::#{type.to_s.capitalize}Field"
          rescue NameError
            Protobuf::Field::MessageField
          end
        end
      end

      def initialize(message_class, rule, type, name, tag, opts={})
        @message_class, @rule, @type, @name, @tag, @opts = message_class, rule, type, name, tag, opts
        modulize_type! unless scalar_type?
      end

      def modulize_type!
        modules = @message_class.to_s.split('::')
        while
          begin
            @type = eval((modules | [@type.to_s]).join('::'))
            break
          rescue NameError
            modules.empty? ? raise($!) : modules.pop
          end
        end
      end

      def scalar_type?
        (STRING_TYPES | NUMERIC_TYPES | BOOLEAN_TYPES).include? @type
      end

      def default_value
        default = @opts[:default]
        case @rule
        when :repeated
          case @type
          when *STRING_TYPES;  TypedArray.new String # TODO Fieldクラスを設定してそのチェックメソッドを使う
          when *NUMERIC_TYPES; TypedArray.new Integer
          when *BOOLEAN_TYPES; TypedArray.new Boolean
          else                 TypedArray.new @type
          end
        when :required, :optional
          if default and scalar_type?
            defult
          else
            case @type
            when *STRING_TYPES;  ''
            when *NUMERIC_TYPES; 0
            when *BOOLEAN_TYPES; false
            else # enum or message
              if default.is_a? Symbol
                @type.module_eval default.to_s
              else
                default
              end
            end
          end
        end
      end

      def define_accessor_to(message_instance)
        message_instance.instance_eval %Q{
          def #{@name}
            @#{@name}
          end

          def #{@name}=(val)
            @#{@name} = val
          end
        }
        message_instance.instance_variable_set "@#{@name}", default_value
      end

      def to_s
        "#{rule} #{type} #{name} = #{tag} [default=#{value}]"
      end
    end

    class StringField < BaseField
    end
    
    class BytesField < BaseField
    end
    
    class Int32Field < BaseField
    end
    
    class Int64Field < BaseField
    end
    
    class Uint32Field < BaseField
    end
    
    class Uint64Field < BaseField
    end
    
    class Sint32Field < BaseField
    end
    
    class Sint64Field < BaseField
    end
    
    class DoubleField < BaseField
    end
    
    class FloatField < BaseField
    end
    
    class Fixed32Field < BaseField
    end
    
    class Fixed64Field < BaseField
    end
    
    class Sfinxed32Field < BaseField
    end
    
    class Sfixed64Field < BaseField
    end
    
    class BoolField < BaseField
    end
    
    class MessageField < BaseField
    end
  end
end
