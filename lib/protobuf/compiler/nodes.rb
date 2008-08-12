module Protobuf
  module Node
    # TODO: should be refactored
    class ToRubyVisitor
      attr_accessor :indent, :context

      def initialize
        @indent = 0
        @context = []
      end

      def write(str)
        ruby << "#{'  ' * @indent}#{str}"
      end

      def increment
        @indent += 1
      end

      def decrement
        @indent -= 1
      end

      def close_ruby
        while 0 < indent
          decrement
          write 'end'
        end
      end

      def ruby
        @ruby ||= []
      end

      def to_s
        @ruby.join("\n")
      end

      def visit(node)
        node.to_rb self 
        self
      end
    end

    class Base
    end
  
    class ProtoNode < Base
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def to_rb(visitor)
        visitor.write <<-eos
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'
        eos
        @children.map{|child| child.to_rb visitor}
        visitor.close_ruby
      end
    end
  
    class ImportNode < Base
      def initialize(path)
        @path = path
      end

      def to_rb(visitor)
        visitor.write "require #{path.inspect}"
      end
    end

    class PackageNode < Base
      def initialize(path_list)
        @path_list = path_list
      end

      def to_rb(visitor)
        @path_list.each do |path|
          visitor.write "module #{path.to_s.capitalize}"
          visitor.increment
        end
      end
    end

    class OptionNode < Base
      def initialize(name_list, value)
        @name_list, @value = name_list, value
      end

      def to_rb(visitor)
        visitor.write "::Protobuf::OPTIONS[:#{@name_list.join('.').inspect}] = #{@value.inspect}"
      end
    end

    class MessageNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def to_rb(visitor)
        visitor.write "class #{@name} < ::Protobuf::Message"
        visitor.increment
        visitor.context.push self.class
        @children.each {|child| child.to_rb visitor}
        visitor.context.pop
        visitor.decrement
        visitor.write "end"
      end
    end

    class ExtendNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def to_rb(visitor)
        visitor.write "class #{@name} < ::Protobuf::Message"
        visitor.increment
        visitor.context.push self.class
        @children.each {|child| child.to_rb visitor}
        visitor.context.pop
        visitor.decrement
        visitor.write "end"
      end
    end

    class EnumNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def to_rb(visitor)
        visitor.write "class #{@name} < ::Protobuf::Enum"
        visitor.increment
        visitor.context.push self.class
        @children.each {|child| child.to_rb visitor}
        visitor.context.pop
        visitor.decrement
        visitor.write "end"
      end
    end

    class EnumFieldNode < Base
      def initialize(name, value)
        @name, @value = name, value
      end

      def to_rb(visitor)
        visitor.write "#{@name} = #{@value}"
      end
    end

    class ServiceNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def to_rb(visitor)
        raise ArgumentError.new('have not implement')
      end
    end

    class RpcNode < Base
      def initialize(name, request, response)
        @name, @request, @response = name, request, response
      end

      def to_rb(visitor)
        raise ArgumentError.new('have not implement')
      end
    end

    class GroupNode < Base
      def initialize(label, name, value, children)
        @label, @name, @value, @children = label, name, value, children
      end

      def to_rb(visitor)
        raise ArgumentError.new('have not implement')
      end
    end

    class FieldNode < Base
      def initialize(label, type, name, value, opts=[])
        @label, @type, @name, @value, @opts = label, type, name, value, opts
      end

      def to_rb(visitor)
        opts = @opts.empty? ? '' : ", #{@opts.map{|k, v| ":#{k} = :#{v}"}.join(', ')}"
        if visitor.context.first == Protobuf::Node::ExtendNode
          opts += ', :extension => true'
        end
        visitor.write "#{@label} :#{@type}, :#{@name}, #{@value}#{opts}"
      end
    end

    class ExtensionsNode < Base
      def initialize(range)
        @range = range
      end

      def to_rb(visitor)
        visitor.write "extensions #{@range.to_s}"
      end
    end

    class ExtensionRangeNode < Base
      def initialize(low, high=nil)
        @low, @high = low, high
      end

      #def to_rb(visitor)
      #end
      
      def to_s
        if @high.nil?
          @low.to_s
        elsif @high == :max
          "#{@low}..Protobuf::Extend::MAX"
        else
          "#{@low}..#{@high}"
        end
      end
    end
  end
end
