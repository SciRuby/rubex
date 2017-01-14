module Rubex
  module AST
    module Statement
      include Rubex::Helpers::NodeTypeMethods
      include Rubex::DataType

      def statement?; true; end

      def == other
        self.class == other.class
      end

      class VarDecl
        include Rubex::AST::Statement
        attr_reader :type, :name, :c_name, :value

        def initialize type, name, value
          @c_name = Rubex::VAR_PREFIX + name
          @name, @value = name, value
          @type = type
        end

        def analyse_statement local_scope
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
          @type =
          if Rubex::TYPE_MAPPINGS.has_key? @type
            Rubex::TYPE_MAPPINGS[@type].new
          elsif Rubex::CUSTOM_TYPES.has_key? @type
            Rubex::CUSTOM_TYPES[@type]
          else
            raise "Cannot decipher type #{type}"
          end
          local_scope.declare_var self
          if @value.is_a? Rubex::AST::Expression
            @value.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope

        end
      end

      class CPtrDecl
        include Rubex::AST::Statement
        attr_reader :type, :name, :value, :c_name

        def initialize dtype, name, value
          @name, @value = name, value
          @c_name = Rubex::POINTER_PREFIX + name
          @type = CPtr.new Rubex::TYPE_MAPPINGS[dtype].new
        end

        def analyse_statement local_scope
          @value.analyse_statement(local_scope) unless @value.nil?
          local_scope.declare_var self
        end

        def generate_code code, local_scope

        end
      end

      class CStructOrUnionDef
        include Rubex::AST::Statement
        attr_reader :name, :declarations, :type, :kind

        def initialize kind, name, declarations
          @declarations = declarations
          if /struct/.match kind
            @kind = :struct
          elsif /union/.match kind
            @kind = :union
          end
          @name = name
        end

        def analyse_statement outer_scope
          local_scope = Rubex::SymbolTable::Scope::StructOrUnion.new outer_scope
          @type = CStructOrUnion.new @kind, @name, @c_name, local_scope

          @declarations.each do |decl|
            decl.analyse_statement local_scope
          end
          Rubex::CUSTOM_TYPES[@name] = @type
        end

        def generate_code code, local_scope
          
        end
      end

      class ForwardDecl
        include Rubex::AST::Statement
        attr_reader :kind, :name, :type

        def initialize kind, name
          @name = name
          if /struct/.match kind
            @kind = :struct
          elsif /union/.match kind
            @kind = :union
          end
          Rubex::CUSTOM_TYPES[@name] = nil
        end

        def analyse_statement local_scope
          
        end

        def generate_code code, local_scope
          
        end
      end # class ForwardDecl

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
          # pp self
          code << @type.printf(@expression.c_code(local_scope))
          code.nl
        end
      end # class Print

      class Return
        include Rubex::AST::Statement
        attr_reader :expression, :type

        def initialize expression
          @expression = expression
        end

        def analyse_statement local_scope
          @expression.analyse_statement local_scope
          @type = @expression.type
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
        include Rubex::AST::Statement
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
            @expr.analyse_statement(local_scope)
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
        include Rubex::AST::Statement
        include Rubex::AST::Statement::IfBlock::Helper

        def initialize expr, statements, if_tail
          @expr, @statements, @if_tail = expr, statements, if_tail
        end

        def generate_code code, local_scope
          generate_code_for_statement "if", code, local_scope
        end

        class Elsif
          attr_reader :expr, :statements, :if_tail
          include Rubex::AST::Statement
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
          include Rubex::AST::Statement
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
        include Rubex::AST::Statement
        attr_reader :type, :array_list, :name, :dimension

        def initialize type, array_ref, array_list
          @name, @array_list = array_ref.name, array_list
          @dimension = array_ref.pos
          @type = Rubex::TYPE_MAPPINGS[type].new
        end

        def analyse_statement local_scope
          @dimension.analyse_statement local_scope
          create_symbol_table_entry local_scope
          return if @array_list.nil?
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
          local_scope.add_carray @name, @dimension, @array_list, @type
        end
      end # class CArrayDecl

      class For
        include Rubex::AST::Statement
        attr_reader :left_expr, :left_op, :middle, :right_op, :right_expr,
                    :statements, :order

        def initialize left_expr, left_op, middle, right_op, right_expr,
          statements
          @left_expr, @left_op, @middle, @right_op, @right_expr =
            left_expr, left_op, middle, right_op, right_expr
          @statements, @order = statements, order
        end

        def analyse_statement local_scope
          @left_expr.analyse_statement local_scope
          @right_expr.analyse_statement local_scope
          @middle = local_scope[@middle] # middle will not be an expr.
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          code << for_loop_header(local_scope)
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
        end

        private

        def for_loop_header local_scope
          for_stmt = ""
          for_stmt << "for (#{@middle.c_name} = #{@left_expr.c_code(local_scope)}"

          if @left_op == '<'
            for_stmt << " + 1"
          elsif @left_op == '>'
            for_stmt << " - 1"
          end

          for_stmt << "; #{@middle.c_name} #{@right_op} #{@right_expr.c_code(local_scope)}; "
          for_stmt << "#{@middle.c_name}"

          if ['>', '>='].include? @right_op
            for_stmt << "--"
          elsif ['<', '<='].include? @right_op
            for_stmt << "++"
          end

          for_stmt << ")"

          for_stmt
        end
      end # class For

      class While
        include Rubex::AST::Statement
        attr_reader :expr, :statements

        def initialize expr, statements
          @expr, @statements = expr, statements
        end

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          stmt = "while (#{@expr.c_code(local_scope)})"
          code << stmt
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
        end
      end # class While
    end # module Statement
  end # module AST
end # module Rubex
