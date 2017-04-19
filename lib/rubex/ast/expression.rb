module Rubex
  module AST
    module Expression

      # Stub for making certain subclasses of Expression not needed statement analysis.
      def analyse_statement local_scope
        nil
      end

      def expression?; true; end

      class Binary
        include Rubex::AST::Expression
        include Rubex::Helpers::NodeTypeMethods

        attr_reader :operator
        attr_accessor :left, :right
        # Final return type of expression
        attr_accessor :type

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
          @@analyse_visited = []
        end

        def analyse_statement local_scope
          analyse_left_and_right_nodes local_scope, self
          analyse_return_type local_scope, self
        end

        def c_code local_scope
          code = ""
          recursive_generate_code(local_scope, code, self)
          code
        end

        def == other
          self.class == other.class && @type  == other.type &&
          @left == other.left  && @right == other.right &&
          @operator == other.operator
        end

      private

        def analyse_left_and_right_nodes local_scope, tree
          if tree.respond_to?(:left)
            analyse_left_and_right_nodes local_scope, tree.left

            if !@@analyse_visited.include?(tree.left.object_id)
              tree.left.analyse_statement(local_scope)
              @@analyse_visited << tree.left.object_id
            end
            
            if !@@analyse_visited.include?(tree.right.object_id)
              tree.right.analyse_statement(local_scope)
              @@analyse_visited << tree.right.object_id
            end

            @@analyse_visited << tree.object_id

            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left
            analyse_return_type local_scope, tree.right

            if ['==', '<', '>', '<=', '>=', '||', '&&'].include? tree.operator
              tree.type = Rubex::DataType::Boolean.new
            else
              if tree.left.type.bool? || tree.right.type.bool?
                raise Rubex::TypeMismatchError, "Operation #{tree.operator} cannot"\
                  "be performed between #{tree.left} and #{tree.right}"
              end
              tree.type = Rubex::Helpers.result_type_for(
                     tree.left.type, tree.right.type)
            end
          end
        end

        def recursive_generate_code local_scope, code, tree
          if tree.respond_to? :left
            code << "( "
            recursive_generate_code local_scope, code, tree.left
            unless tree.left.respond_to?(:left)
              code << "#{tree.left.c_code(local_scope)}"
            end

            code << " #{tree.operator} "

            unless tree.right.respond_to?(:right)
              code << "#{tree.right.c_code(local_scope)}"
            end
            recursive_generate_code local_scope, code, tree.right
            code << " )"
          end
        end
      end # class Binary

      class Unary
        include Rubex::AST::Expression
        attr_reader :operator, :expr, :type

        def initialize operator, expr
          @operator, @expr = operator, expr
        end

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
          @type = @expr.type
        end

        def c_code local_scope
          "#{@operator} #{@expr.c_code(local_scope)}"
        end
      end # class Unary

      class ArrayRef
        include Rubex::AST::Expression
        attr_reader :name, :pos, :type

        def initialize name, pos
          @name, @pos = name, pos
        end

        def analyse_statement local_scope, struct_scope=nil
          @pos.analyse_statement local_scope
          if struct_scope.nil?
            @name = local_scope[@name]
          else
            @name = struct_scope[@name]
          end

          @type = @name.type.type # assign actual type
        end

        def c_code local_scope
          "#{@name.c_code(local_scope)}[#{@pos.c_code(local_scope)}]"
        end
      end # class ArrayRef

      module Literal
        include Rubex::AST::Expression
        attr_reader :name

        def initialize name
          @name = name
        end

        def c_code local_scope
          @name
        end

        def c_name
          @name
        end

        def literal?; true; end

        def == other
          self.class == other.class && @name == other.name
        end

        class Double
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::F64.new
          end
        end

        class Int
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::Int.new
          end
        end

        class Str
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::CStr.new
          end

          def c_code local_scope
            "\"#{@name}\""
          end
        end

        class Char
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::Char.new
          end
        end # class Char

        class True
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::TrueType.new
          end
        end # class True

        class False
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::FalseType.new
          end
        end # class False

        class Nil
          include Rubex::AST::Expression::Literal

          def type
            Rubex::DataType::NilType.new
          end
        end # class Nil
      end # module Literal

      # Singular name node with no sub expressions.
      class Name
        include Rubex::AST::Expression
        attr_reader :name, :entry, :type

        def initialize name
          @name = name
        end

        def analyse_statement local_scope
          @entry = local_scope.find @name

          # FIXME: Figure out a way to perform compile time checking of expressions
          #   to see if the said Ruby methods are actually present in the Ruby
          #   runtime. Maybe read symbols in the Ruby interpreter and load them
          #   as a pre-compilation step?

          # If entry is not present, assume its a Ruby method call to some method
          #   outside of the current Rubex scope.
          if !@entry
            local_scope.add_ruby_method name: @name, c_name: @name, extern: true
            @entry = local_scope.find @name
          end
          # If the entry is a RubyMethod, it should be interpreted as a command
          # call. So, make the @name a CommandCall Node.
          if @entry.type.ruby_method?
            @name = Rubex::AST::Expression::CommandCall.new(
              Name.new("self"), @name, [])
            @name.analyse_statement local_scope
          end

          if @entry.type.alias_type? || @entry.type.ruby_method?
            @type = @entry.type.type
          else
            @type = @entry.type
          end
        end

        def c_code local_scope
          if @entry.type.ruby_method?
            @name.c_code(local_scope)
          else
            @entry.c_name
          end
        end
      end # class Name

      class MethodCall
        include Rubex::AST::Expression
        attr_reader :method_name, :type

        def initialize method_name, invoker, arg_list
          @method_name, @invoker, @arg_list = method_name, invoker, arg_list
        end

        # Analyse a method call. If the method that is being called is defined
        #   in a class in a Rubex file, it can easily be interpreted as a Ruby
        #   method. However, in case it is not, a new symtab entry will be created
        #   which will mark the method as 'extern' so that future calls to that
        #   same method can be simply pulled from the symtab.
        # local_scope is the local method scope.
        def analyse_statement local_scope
          entry = local_scope.find(@method_name)
          if !entry
            local_scope.add_ruby_method(name: @method_name, 
              c_name: @method_name, extern: true, scope: :outer)
            entry = local_scope.find(@method_name)
            entry.type.arg_list = @arg_list
          end

          # a symtab entry for a predeclared extern C func.
          # FIXME: C functions should have the type CFunction like RubyMethod.
          #   Currently their type is set to their return type.
          if entry && entry.extern? 
            @type = entry.type
          else
            @type = Rubex::DataType::RubyObject.new
          end
        end

        def c_code local_scope
          entry = local_scope.find(@method_name)
          if entry
            return code_for_c_method_call(local_scope, entry)
          else
            return code_for_ruby_method_call(local_scope)
          end
        end

      private
        def code_for_c_method_call local_scope, entry
          str = "#{entry.c_name}("
          str << @arg_list.map { |a| a.c_code(local_scope) }.join(",")
          str << ")"
          str
        end

        def code_for_ruby_method_call local_scope
          str = "rb_funcall("
          str << "#{@invoker.c_code(local_scope)}, "
          str << "rb_intern(\"#{@method_name}\"), "
          str << "#{@arg_list.size}"
          @arg_list.each do |arg|
            str << " ,#{arg.c_code(local_scope)}"
          end
          str << ", NULL" if @arg_list.empty?
          str << ")"
          str
        end
      end

      class CommandCall
        include Rubex::AST::Expression
        attr_reader :expr, :command, :arg_list, :type

        def initialize expr, command, arg_list
          @expr, @command, @arg_list = expr, command, arg_list
        end

        # Analyse the command call. If the @command is found in the symbol table,
        #   it is either a struct member or a method call. If not found, it is
        #   assumed to be a Ruby method call and passed on the MethodCall node
        #   where it is interpreted likewise. The upside is that Rubex can call
        #   arbitrary Ruby methods that are defined in external Ruby scripts and
        #   not visible to Rubex at compile time. The downside is that errors with
        #   such methods will be visible to the programmer only during runtime.
        def analyse_statement local_scope
          @arg_list.each do |arg|
            arg.analyse_statement local_scope
          end
          # Case for implicit 'self' when a method in the class itself is being called.
          if @expr.nil? 
            entry = local_scope.find(@command)
            if entry && !entry.extern?
              @expr = Expression::Name.new "self"
            end
          end
          # if command is extern @expr will be nil.
          @expr.analyse_statement(local_scope) unless @expr.nil?
          analyse_command_type local_scope
        end

        def c_code local_scope
          # Interpreted as a method call
          if @command.is_a? Rubex::AST::Expression::MethodCall
            @command.c_code(local_scope)
          else # interpreted as referencing the contents of a struct
            "#{@expr.c_code(local_scope)}.#{@command.c_code(local_scope)}"
          end
        end

      private

        def analyse_command_type local_scope
          if @expr && @expr.type.struct_or_union?
            scope = @expr.type.scope
            if @command.is_a? String
              @command = Expression::Name.new @command
              @command.analyse_statement scope
            end

            if !scope.has_entry?(@command.name)
              raise "Entry #{@command.name} does not exist in #{@expr}."
            end

            if @command.is_a? Rubex::AST::Expression::ArrayRef
              @command.analyse_statement local_scope, scope
            end
          else
            @command = Expression::MethodCall.new @command, @expr, @arg_list
            @command.analyse_statement local_scope
          end
          @type = @command.type
        end
      end # class CommandCall
    end # module Expression
  end # module AST
end # module Rubex
