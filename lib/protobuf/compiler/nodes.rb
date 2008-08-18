module Protobuf
  module Node
    class Base
      def accept_rpc_creator(vistor)
      end
    end
  
    class ProtoNode < Base
      attr_reader :children

      def initialize(children)
        @children = children
      end

      def accept_message_creator(visitor)
        visitor.write <<-eos
require 'protobuf/message/message'
require 'protobuf/message/enum'
require 'protobuf/message/service'
require 'protobuf/message/extend'
        eos
        @children.map{|child| child.accept_message_creator visitor}
        visitor.close_ruby
      end

      def accept_rpc_creator(visitor)
        @children.map{|child| child.accept_rpc_creator visitor}
      end
    end
  
    class ImportNode < Base
      def initialize(path)
        @path = path
      end

      def accept_message_creator(visitor)
        visitor.write "require '#{visitor.required_message_from_proto @path}'"
      end
    end

    class PackageNode < Base
      def initialize(path_list)
        @path_list = path_list
      end

      def accept_message_creator(visitor)
        @path_list.each do |path|
          visitor.write "module #{path.to_s.capitalize}"
          visitor.increment
        end
      end

      def accept_rpc_creator(visitor)
        visitor.package = @path_list.dup
      end
    end

    class OptionNode < Base
      def initialize(name_list, value)
        @name_list, @value = name_list, value
      end

      def accept_message_creator(visitor)
        visitor.write "::Protobuf::OPTIONS[:#{@name_list.join('.').inspect}] = #{@value.inspect}"
      end
    end

    class MessageNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def accept_message_creator(visitor)
        visitor.write "class #{@name} < ::Protobuf::Message"
        visitor.in_context self.class do 
          @children.each {|child| child.accept_message_creator visitor}
        end
        visitor.write "end"
      end
    end

    class ExtendNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def accept_message_creator(visitor)
        visitor.write "class #{@name} < ::Protobuf::Message"
        visitor.in_context self.class do 
          @children.each {|child| child.accept_message_creator visitor}
        end
        visitor.write "end"
      end
    end

    class EnumNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def accept_message_creator(visitor)
        visitor.write "class #{@name} < ::Protobuf::Enum"
        visitor.in_context self.class do 
          @children.each {|child| child.accept_message_creator visitor}
        end
        visitor.write "end"
      end
    end

    class EnumFieldNode < Base
      def initialize(name, value)
        @name, @value = name, value
      end

      def accept_message_creator(visitor)
        visitor.write "#{@name} = #{@value}"
      end
    end

    class ServiceNode < Base
      def initialize(name, children)
        @name, @children = name, children
      end

      def accept_message_creator(visitor)
        # do nothing
        #visitor.write "class #{@name} < ::Protobuf::Service"
        #visitor.in_context self.class do 
        #  @children.each {|child| child.accept_message_creator visitor}
        #end
        #visitor.write "end"
      end

      def accept_rpc_creator(visitor)
        visitor.current_service = @name
        @children.each {|child| child.accept_rpc_creator visitor}
      end
    end

    class RpcNode < Base
      def initialize(name, request, response)
        @name, @request, @response = name, request, response
      end

      def accept_message_creator(visitor)
        # do nothing
        #visitor.write "rpc :#{@name}, :request => :#{@request}, :response => :#{@response}"
      end

      def accept_rpc_creator(visitor)
        visitor.add_rpc @name, @request, @response
      end
    end

    class GroupNode < Base
      def initialize(label, name, value, children)
        @label, @name, @value, @children = label, name, value, children
      end

      def accept_message_creator(visitor)
        raise ArgumentError.new('have not implement')
      end
    end

    class FieldNode < Base
      def initialize(label, type, name, value, opts=[])
        @label, @type, @name, @value, @opts = label, type, name, value, opts
      end

      def accept_message_creator(visitor)
        opts = @opts.empty? ? '' : ", #{@opts.map{|k, v| ":#{k} => :#{v}"}.join(', ')}"
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

      def accept_message_creator(visitor)
        visitor.write "extensions #{@range.to_s}"
      end
    end

    class ExtensionRangeNode < Base
      def initialize(low, high=nil)
        @low, @high = low, high
      end

      #def accept_message_creator(visitor)
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
