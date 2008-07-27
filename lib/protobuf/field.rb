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
      def typed_default_value(default=nil)
        default or ''
      end

      def acceptable?(val)
        val.instance_of? String
      end
    end
    
    class BytesField < Base
      def typed_default_value(default=nil)
        default or ''
      end
    end

    class Numeric < Base
      def typed_default_value(default=nil)
        default or 0
      end
    end
    
    class Int32Field < Numeric
    end
    
    class Int64Field < Numeric
    end
    
    class Uint32Field < Numeric
    end
    
    class Uint64Field < Numeric
    end
    
    class Sint32Field < Numeric
    end
    
    class Sint64Field < Numeric
    end
    
    class DoubleField < Numeric
    end
    
    class FloatField < Numeric
    end
    
    class Fixed32Field < Numeric
    end
    
    class Fixed64Field < Numeric
    end
    
    class Sfinxed32Field < Numeric
    end
    
    class Sfixed64Field < Numeric
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
    end

    class Enum < Base
      def acceptable?(val)
        type.valid_tag? val
      end
    end
  end
end
