module Protobuf
  module Field
    def self.build(message_class, rule, type, name, tag, opts={})
      Base.build message_class, rule, type, name, tag, opts
    end

    class InvalidRuleError < StandardError; end

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

    class Base
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

      attr_accessor :message_class, :rule, :type, :name, :tag, :default

      def initialize(message_class, rule, type, name, tag, opts={})
        @message_class, @rule, @type, @name, @tag, @default = message_class, rule, type, name, tag, opts[:default]
      end

      def default_value
        case rule
        when :repeated
          TypedArray.new self
        when :required, :optional
          typed_default_value default
        else
          raise InvalidRuleError
        end
      end

      def typed_default_value(default=nil)
        default
      end

      def define_accessor_to(message_instance)
        message_instance.instance_eval %Q{
          def #{name}
            @#{name}
          end

          def #{name}=(val)
            @#{name} = val
          end
        }
        message_instance.instance_variable_set "@#{name}", default_value
      end

      def to_s
        "#{rule} #{type} #{name} = #{tag} [default=#{default}]"
      end
    end

    class StringField < Base
      def typed_default_value(default=nil)
        default or ''
      end
    end
    
    class BytesField < Base
      def typed_default_value(default=nil)
        default or ''
      end
    end

    class AbstractNumeric < Base
      def typed_default_value(default=nil)
        default or 0
      end
    end
    
    class Int32Field < AbstractNumeric
    end
    
    class Int64Field < AbstractNumeric
    end
    
    class Uint32Field < AbstractNumeric
    end
    
    class Uint64Field < AbstractNumeric
    end
    
    class Sint32Field < AbstractNumeric
    end
    
    class Sint64Field < AbstractNumeric
    end
    
    class DoubleField < AbstractNumeric
    end
    
    class FloatField < AbstractNumeric
    end
    
    class Fixed32Field < AbstractNumeric
    end
    
    class Fixed64Field < AbstractNumeric
    end
    
    class Sfinxed32Field < AbstractNumeric
    end
    
    class Sfixed64Field < AbstractNumeric
    end
    
    class BoolField < Base
      def typed_default_value(default=nil)
        default or false
      end
    end
    
    class MessageField < Base
      def initialize(message_class, rule, type, name, tag, opts={})
        super
        modulize_type!
      end

      def modulize_type!
        modules = message_class.to_s.split('::')
        while
          begin
            @type = eval((modules | [type.to_s]).join('::'))
            break
          rescue NameError
            modules.empty? ? raise($!) : modules.pop
          end
        end
      end

      def typed_default_value(default=nil)
        if default.is_a? Symbol
          type.module_eval default.to_s
        else
          default
        end
      end
    end
  end
end
