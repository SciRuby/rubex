module Rubex
  module AST
    module Statement
      include Rubex::Helpers::NodeTypeMethods

      def statement?; true; end

      def == other
        self.class == other.class
      end

      class VarDecl
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
          local_scope.declare_var self
          if @value.is_a? Rubex::AST::Expression
            @value.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope

        end
      end

      class Print
        include Rubex::AST::Statement
        attr_reader :expression, :type

        def initialize expression
          @expression = expression
        end

        def analyse_statement local_scope
          if @expression.is_a? Rubex::AST::Expression
            @expression.analyse_statement(local_scope)
            @type = @expression.type
          elsif local_scope.has_entry? @expression
            @expression = local_scope[@expression]
            @type = @expression.type
          end
          @type = @type.type if @type.carray?
        end

        def generate_code code, local_scope
          code << @type.printf(@expression.c_code(local_scope))
          code.nl
        end
      end

      class Return
        include Rubex::AST::Statement
        attr_reader :expression, :type

        def initialize expression
          @expression = expression
        end

        def analyse_statement local_scope
          if local_scope.has_entry? @expression # simple IDENTIFIER
            @expression = local_scope[@expression]
            @type = @expression.type
          else
            @expression.analyse_statement local_scope
            case @expression
            when Rubex::AST::Expression::ArrayRef
              @type = @expression.type.type
            when Rubex::AST::Expression::Binary, Rubex::AST::Expression::Literal
              @type = @expression.type
            else
              raise "Cannot recognize type of #{@expression}."
            end
          end

          # TODO: Raise error if type as inferred from the
          # is not compatible with the return statement type.
        end

        def generate_code code, local_scope
          code << "return "
          code << @type.to_ruby_function("#{@expression.c_code(local_scope)}") + ";"
          code.nl
        end
      end # class Return

      class Assign
        attr_reader :lhs, :rhs

        def initialize lhs, rhs
          @lhs, @rhs = lhs, rhs
        end

        def analyse_statement local_scope
          # LHS symbol has been declared.
          @rhs.analyse_statement(local_scope) if @rhs.is_a? Rubex::AST::Expression

          if @lhs.is_a? Rubex::AST::Expression
            @lhs.analyse_statement(local_scope)
          elsif local_scope.has_entry? @lhs
            @lhs = local_scope[@lhs]
          else
            # If LHS is not found in the symtab assume that its a Ruby object being assigned.
            local_scope.add_ruby_obj @lhs, @rhs
            @lhs = local_scope[@lhs]
            @ruby_obj_init = true
          end
        end

        def generate_code code, local_scope
          str = "#{@lhs.c_code(local_scope)} = "
          if @ruby_obj_init
            if @rhs.is_a?(Rubex::AST::Expression::Literal::Char)
              str << "#{@rhs.type.to_ruby_function(@rhs.c_code(local_scope), true)}"
            else
              str << "#{@rhs.type.to_ruby_function(@rhs.c_code(local_scope))}"
            end
          else
            str << "#{@rhs.c_code(local_scope)}"
          end
          str << ";"
          code << str
          code.nl
        end
      end # class Assign

      class IfBlock
        module Helper
          def analyse_statement local_scope
            if @expr.is_a? Rubex::AST::Expression
              @expr.analyse_statement(local_scope)
            else
              @expr = local_scope[@expr]
            end

            @statements.each do |stat|
              stat.analyse_statement local_scope
            end

            unless @if_tail.empty?
              @if_tail.each do |tail|
                tail.analyse_statement local_scope
              end
            end
          end

          def generate_code_for_statement stat, code, local_scope
            if stat != "else"
              code << "#{stat} (#{@expr.c_code(local_scope)}) "
            else
              code << "#{stat}"
            end

            code.block do
              @statements.each do |stat|
                stat.generate_code code, local_scope
                code.nl
              end
            end

            if stat != "else"
              unless @if_tail.empty?
                @if_tail.each do |tail|
                  tail.generate_code code, local_scope
                end
              end
            end
          end
        end # module Helper

        attr_reader :expr, :statements, :if_tail
        include Rubex::AST::Statement::IfBlock::Helper

        def initialize expr, statements, if_tail
          @expr, @statements, @if_tail = expr, statements, if_tail
        end

        def generate_code code, local_scope

          generate_code_for_statement "if", code, local_scope
        end

        class Elsif
          attr_reader :expr, :statements, :if_tail
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize expr, statements, if_tail
            @expr, @statements, @if_tail = expr, statements, if_tail
          end

          def generate_code code, local_scope
            generate_code_for_statement "else if", code, local_scope
          end
        end # class Elsif

        class Else
          attr_reader :statements
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize statements
            @statements = statements
          end

          def analyse_statement local_scope
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope
            generate_code_for_statement "else", code, local_scope
          end
        end # class Else
      end # class IfBlock

      class CArrayDecl
        attr_reader :type, :array_list, :array_ref, :dimension

        def initialize type, array_ref, array_list
          @array_ref, @array_list = array_ref, array_list
          @dimension = @array_ref.pos
          @type = Rubex::TYPE_MAPPINGS[type].new
        end

        def analyse_statement local_scope
          create_symbol_table_entry local_scope
          return if @array_list.nil?
          if @dimension < @array_list.size
            raise Rubex::ArrayLengthMismatchError, "Array #{@array_ref.name}"\
            " should have max #{@dimension} elements but has #{@array_list.size}."
          end

          analyse_array_list local_scope
          verify_array_list_types local_scope
        end

        def generate_code code, local_scope

        end

      private

        def analyse_array_list local_scope
          @array_list.each do |expr|
            if expr.is_a? Rubex::AST::Expression
              expr.analyse_statement(local_scope)
            elsif local_scope.has_entry?(expr)
              expr = local_scope[expr]
            elsif expr.is_a? Rubex::AST::Literal

            else
              raise Rubex::SymbolNotFoundError, "Symbol #{expr} not found anywhere."
            end
          end
        end

        def verify_array_list_types local_scope
          @array_list.all? do |expr|
            return true if @type > expr.type
            raise "Specified type #{@type} but list contains #{expr.type}."
          end
        end

        def create_symbol_table_entry local_scope
          local_scope.add_carray @array_ref, @array_list, @type
        end
      end # class CArrayDecl
    end # module Statement
  end # module AST
end # module Rubex
