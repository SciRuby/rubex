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
            tree.left.analyse_statement(local_scope)
            tree.right.analyse_statement(local_scope)
            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left
            analyse_return_type local_scope, tree.right

            if ['==', '<', '>', '<=', '>='].include? tree.operator
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
            recursive_generate_code local_scope, code, tree.left
            unless tree.left.respond_to?(:left)
              code << "( " if !tree.left.is_a?(Rubex::AST::Expression::Unary)
              code << "#{tree.left.c_code(local_scope)}"
            end
            code << " #{tree.operator} "
            unless tree.right.respond_to?(:right)
              code << "#{tree.right.c_code(local_scope)}"
              code << " )" if !tree.right.is_a?(Rubex::AST::Expression::Unary)
            end
            recursive_generate_code local_scope, code, tree.right
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
          puts " \n\n\n>>>>> #{@name}"
          if struct_scope.nil?
            @name = local_scope[@name]
          else
            @name = struct_scope[@name]
          end
          
          @type = @name.type.type # assign actual type
          puts ">>>>>>> #{@type}"
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

        # class Str; include Rubex::AST::Expression::Literal;  end

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
          @entry = local_scope[@name]
          @type = @entry.type
        end

        def c_code local_scope
          @entry.c_name
        end
      end # class Name

      class MethodCall
        include Rubex::AST::Expression
        attr_reader :name, :type

        def initialize name
          @name = name
          @type = Rubex::DataType::RubyObject.new
        end

        def c_code local_scope
          @name
        end
      end

      class CommandCall
        include Rubex::AST::Expression
        attr_reader :expr, :command, :arg_list, :type

        def initialize expr, command, arg_list
          @expr, @command, @arg_list = expr, command, arg_list
        end

        def analyse_statement local_scope
          @arg_list.each do |arg|
            arg.analyse_statement local_scope
          end
          @expr.analyse_statement local_scope
          analyse_command_type local_scope
        end

        def c_code local_scope
          if @command.is_a? Rubex::AST::Expression::MethodCall
            exp = "rb_funcall("
            exp << "#{@expr.c_code(local_scope)}, rb_intern(\"#{@command}\"), "
            exp << "#{@arg_list.size}"
            @arg_list.each do |arg|
              exp << " ,#{arg.c_code(local_scope)}"
            end
            exp << ", NULL" if @arg_list.empty?
            exp << ")"
            optimize_method_call(exp, local_scope) if @type.object?
          else
            "#{@expr.c_code(local_scope)}.#{@command.c_code(local_scope)}"
          end
        end

      private

        def optimize_method_call exp, local_scope
          optimized = ""
          # Guess that the Ruby object is a string. Check if yes, and optimize
          #   the call to size with RSTRING_LEN.
          if ['size', 'length'].include? @command
            optimized << "RB_TYPE_P(#{@expr.c_code(local_scope)}, T_STRING) ? "
            optimized << "RSTRING_LEN(#{@expr.c_code(local_scope)}) : "
            optimized << exp
          end
          optimized
        end

        def analyse_command_type local_scope
          if @expr.type.struct_or_union? # this is a struct
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
            @command = Expression::MethodCall.new @command
          end

          @type = @command.type
        end
      end # class CommandCall
    end # module Expression
  end # module AST
end # module Rubex
