module Rubex
  module AST
    module Statement
      class VariableDeclaration
        include Rubex::AST::Statement
        attr_reader :type, :name, :c_name, :value

        def initialize type, name, value=nil
          unless Rubex::TYPE_MAPPINGS.has_key?(type)
            raise "type #{type} is not supported."
          end

          @type, @name, @value = Rubex::TYPE_MAPPINGS[type].new, name, value
          @c_name = Rubex::VAR_PREFIX + name
        end

        def analyse_statement local_scope
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
        end

        def generate_code code, local_scope

        end
      end

      class Print
        include Rubex::AST::Statement
        attr_reader :expression, :print_type

        def initialize expression
          @expression = expression
        end

        def analyse_statement local_scope
          if @expression.is_a? String
            entry = local_scope[@expression]
            raise "Invalid expression #{@expression} to print." unless entry
            @print_type = entry.type
          elsif @expression.class.to_s =~ "Rubex::AST::Expression"
            # TODO: Determine print type of expression.
          end
        end

        def generate_code code, local_scope
          entry = local_scope[@expression]
          type = entry.type

          code.new_line
          code << type.printf(entry.c_name)
          code.new_line
        end
      end

      class Return
        include Rubex::AST::Statement
        attr_reader :expression, :return_type

        def initialize expression
          @expression = expression
        end

        def analyse_statement local_scope
          case @expression
          when Rubex::AST::Expression::Binary
            left  = @expression.left
            right = @expression.right

            left_type = local_scope[left].type
            right_type = local_scope[right].type

            @return_type = result_type_for left_type, right_type
          else # assume its an IDENTIFIER
            entry = local_scope[@expression]
            @return_type = entry.type
          end

          # TODO: Raise error if return_type as inferred from the
          # is not compatible with the return statement type.
        end

        def generate_code code, local_scope
          code << "return "
          case @expression
          when Rubex::AST::Expression::Binary
            left  = @expression.left
            right = @expression.right
            code << @return_type.to_ruby_function(
              "#{local_scope[left].c_name} #{@expression.operator} #{local_scope[right].c_name}")
            code << ";"
            code.new_line
          else
            entry = local_scope[@expression]
            if local_scope.return_type.object?
              code << if @return_type.object?
                "#{entry.c_name}"
              else
                @return_type.to_ruby_function("#{entry.c_name}")
              end
            else
              raise "C functions not yet implemented. Can only return object."
            end

            code << ";"
            code.nl
          end
        end

       private

        def result_type_for left_type, right_type
          type = Rubex::DataType

          if left_type.class == right_type.class
            return left_type.class.new
          end
        end
      end

      class Assign
        attr_reader :lhs, :rhs

        def initialize lhs, rhs
          @lhs, @rhs = lhs, rhs
        end

        def analyse_statement local_scope
          # LHS symbol has been declared.
          @lhs.analyse_statement(local_scope) if @lhs.is_a? Rubex::AST::Expression
          @rhs.analyse_statement(local_scope) if @rhs.is_a? Rubex::AST::Expression

          if local_scope.has_entry? @lhs
            lhs = local_scope[@lhs]
            # TODO: Type checking between lhs and rhs. Also see if LHS is a legit
            # lvalue.
          else
            # If LHS is an IDENTIFIER assume that its a Ruby object being assigned.
            local_scope.add_ruby_obj @lhs, @rhs
            @ruby_obj_init = true
          end
        end

        def generate_code code, local_scope
          str = "#{local_scope[@lhs].c_name} = "
          if @ruby_obj_init
            str << "#{@rhs.return_type.to_ruby_function(@rhs.c_code(local_scope))}"
          else
            str << "#{@rhs.c_code(local_scope)}"
          end
          str << ";\n"
          code << str
        end
      end # class Assign

      class IfBlock
        attr_reader :expr, :statements

        def initialize expr, statements
          @expr, @statements = expr, statements
        end

        def analyse_statement local_scope
          if @expr.is_a? Rubex::AST::Expression
            @expr.analyse_statement(local_scope)
          else
            @expr = local_scope[@expr]
          end

          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          code << "if (#{@expr.c_code(local_scope)}) "
          code.lbrace
          code.nl
          code.indent
          @statements.each do |stat|
            stat.generate_code code, local_scope
            code.nl
          end
          code.dedent
          code.rbrace
          code.nl
        end

        class Elsif
          attr_reader :expr, :statements

          def initialize expr, statements
            @expr, @statements = expr, statements
          end

          def analyse_statement local_scope
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope

          end
        end # class Elsif

        class Else
          attr_reader :statements

          def initialize statements
            @statements = statements
          end

          def analyse_statement local_scope
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope

          end
        end # class Else
      end
    end
  end
end
