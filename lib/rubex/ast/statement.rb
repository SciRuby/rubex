module Rubex
  module AST
    module Statement
      include Rubex::Helpers::NodeTypeMethods
      include Rubex::DataType

      # File name and line number of statement in "file_name:lineno" format.
      attr_reader :location

      def initialize location
        @location = location
      end

      def statement?; true; end

      def == other
        self.class == other.class
      end

      def generate_code code, local_scope
        code.write_location @location
      end

      class VarDecl
        include Rubex::AST::Statement
        # The name with which this particular variable can be identified with
        #   in the symbol table.
        attr_reader :name
        attr_reader :type, :value

        def initialize type, name, value, location
          super(location)
          @name, @value = name, value
          @type = type
        end

        def analyse_statement local_scope, extern: false
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
          @type =
          if Rubex::TYPE_MAPPINGS.has_key? @type
            Rubex::TYPE_MAPPINGS[@type].new
          elsif Rubex::CUSTOM_TYPES.has_key? @type
            Rubex::CUSTOM_TYPES[@type]
          else
            raise "Cannot decipher type #{@type}"
          end
          c_name = extern ? @name : Rubex::VAR_PREFIX + @name
          @value.analyse_statement(local_scope) if @value

          local_scope.declare_var name: @name, c_name: c_name, type: @type,
            value: @value, extern: extern
        end

        def rescan_declarations scope
          if @type.is_a? String
            @type = Rubex::CUSTOM_TYPES[@type]
            scope[@name].type = @type
          end
        end

        def generate_code code, local_scope

        end
      end

      class CPtrDecl
        include Rubex::AST::Statement
        attr_reader :type, :name, :value

        def initialize dtype, name, value, location
          super(location)
          @name, @value = name, value
          @type = dtype
        end

        def analyse_statement local_scope, extern: false
          @type =
          if Rubex::TYPE_MAPPINGS.has_key? @type
            Rubex::TYPE_MAPPINGS[@type].new
          elsif Rubex::CUSTOM_TYPES.has_key? @type
            Rubex::CUSTOM_TYPES[@type]
          else
            raise "Cannot decipher type #{@type}"
          end
          c_name = extern ? @name : Rubex::POINTER_PREFIX + @name
          @type = CPtr.new @type
          @value.analyse_statement(local_scope) if @value

          local_scope.declare_var name: @name, c_name: c_name, type: @type,
            value: @value, extern: extern
        end

        def rescan_declarations scope
          if @type.type.is_a? String
            @type = CPtr.new Rubex::CUSTOM_TYPES[@type.type]
            scope[@name].type = @type
          end
        end

        def generate_code code, local_scope

        end
      end

      class CArrayDecl
        include Rubex::AST::Statement
        attr_reader :type, :array_list, :name, :dimension

        def initialize type, array_ref, array_list, location
          super(location)
          @name, @array_list = array_ref.name, array_list
          @dimension = array_ref.pos
          @type = Rubex::TYPE_MAPPINGS[type].new
        end

        def analyse_statement local_scope, extern: false
          @dimension.analyse_statement local_scope
          create_symbol_table_entry local_scope
          return if @array_list.nil?
          analyse_array_list local_scope
          verify_array_list_types local_scope
        end

        def generate_code code, local_scope

        end

        def rescan_declarations local_scope

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
          local_scope.add_carray(name: @name, c_name: Rubex::ARRAY_PREFIX + @name,
            dimension: @dimension, type: @type, value: @array_list)
        end
      end # class CArrayDecl

      class CStructOrUnionDef
        include Rubex::AST::Statement
        attr_reader :name, :declarations, :type, :kind, :entry

        def initialize kind, name, declarations, location
          super(location)
          @declarations = declarations
          if /struct/.match kind
            @kind = :struct
          elsif /union/.match kind
            @kind = :union
          end
          @name = name
        end

        def analyse_statement outer_scope, extern: false
          local_scope = Rubex::SymbolTable::Scope::StructOrUnion.new(
            @name, outer_scope)
          if extern
            c_name = @kind.to_s + " " + @name
          else
            c_name = Rubex::TYPE_PREFIX + local_scope.klass_name + "_" + @name
          end
          @type = Rubex::DataType::CStructOrUnion.new(@kind, @name, c_name, 
            local_scope)

          @declarations.each do |decl|
            decl.analyse_statement local_scope, extern: extern
          end
          Rubex::CUSTOM_TYPES[@name] = @type
          @entry = outer_scope.declare_sue(name: @name, c_name: c_name,
            type: @type, extern: extern)
        end

        def generate_code code, local_scope=nil

        end

        def rescan_declarations local_scope
          struct_scope = Rubex::CUSTOM_TYPES[@name].scope
          @declarations.each do |decl|
            decl.respond_to?(:rescan_declarations) and
            decl.rescan_declarations(struct_scope)
          end
        end
      end

      class ForwardDecl
        include Rubex::AST::Statement
        attr_reader :kind, :name, :type, :c_name

        def initialize kind, name, location
          super(location)
          @name = name
          if /struct/.match kind
            @kind = :struct
          elsif /union/.match kind
            @kind = :union
          end
          Rubex::CUSTOM_TYPES[@name] = @name
        end

        def analyse_statement local_scope, extern: false
          @c_name = Rubex::TYPE_PREFIX + local_scope.klass_name + "_" + @name
          @type = Rubex::DataType::TypeDef.new("#{@kind} #{@name}", @c_name, type)
          local_scope.declare_type self
        end

        def rescan_declarations local_scope
          @type = Rubex::DataType::TypeDef.new("#{@kind} #{@name}", @c_name,
            Rubex::CUSTOM_TYPES[@name])
        end

        def generate_code code, local_scope

        end
      end # class ForwardDecl

      class Print
        include Rubex::AST::Statement

        # An Array containing expressions that are passed to the print statement.
        #   Can either contain a single string containing interpolated exprs or
        #   a set of comma separated exprs. For example, the print statement can
        #   either be of like:
        #     print "Hello #{a} world!"
        #   OR
        #     print "Hello", a, " world!"
        attr_reader :expressions

        def initialize expressions, location
          super(location)
          @expressions = expressions
        end

        def analyse_statement local_scope
          @expressions.each do |expr|
            expr.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          # if @expressions.size == 1 && @expressions[0].type.cstr?
          #   exprs = resolve_cstring_interpolations_if_any
          #   #TODO: figure out a way to parse the individual strings into AST nodes.
          # else
          super
          str = "printf("
          str << "\"#{prepare_format_string}\""
          @expressions.each do |expr|
            str << ", #{inspected_expr(expr, local_scope)}"
          end
          str << ");"

          code << str
          code.nl
        end

      private

        def inspected_expr expr, local_scope
          obj = expr.c_code(local_scope)
          if expr.type.object?
            "RSTRING_PTR(rb_funcall(#{obj}, rb_intern(\"inspect\"), 0, NULL))"
          else
            obj
          end  
        end

        def prepare_format_string
          format_string = ""
          @expressions.each do |expr|
            format_string << expr.type.p_formatter
          end

          format_string
        end

        # Method not currently in use. Will be after string interpolation using
        # a Ruby-like #{} syntax is figured out.
        def resolve_cstring_interpolations_if_any
          string = @expressions[0].name
          i = 0
          exprs = []

          while i < string.size
            if string[i] == "#"
              i += 1

              if string[i] == "{"
                expr = ""
                i += 1
                while string[i] != "}"
                  expr << string[i]
                  i += 1
                end
                i += 1
                exprs << expr
              else # go back cuz if its just a # then its a part of string.
                i -= 1
              end
            end

            str_part = ""
            while i < string.size
              break if string[i] == "#"
              str_part << string[i]
              i += 1
            end

            exprs << str_part unless str_part.empty?
          end

          exprs
        end
      end # class Print

      class Return
        include Rubex::AST::Statement
        attr_reader :expression, :type

        def initialize expression, location
          super(location)
          @expression = expression
        end

        def analyse_statement local_scope
          @expression.analyse_statement local_scope
          @type = @expression.type
          # TODO: Raise error if type as inferred from the
          # is not compatible with the return statement type.
        end

        def generate_code code, local_scope
          super
          code << "return "
          code << @type.to_ruby_object("#{@expression.c_code(local_scope)}") + ";"
          code.nl
        end
      end # class Return

      class Assign
        include Rubex::AST::Statement
        attr_reader :lhs, :rhs

        def initialize lhs, rhs, location
          super(location)
          @lhs, @rhs = lhs, rhs
        end

        def analyse_statement local_scope
          # LHS symbol has been declared.
          @rhs.analyse_statement(local_scope) if @rhs.is_a? Rubex::AST::Expression

          # FIXME: @lhs is always going to be Expression. How to remove this conditional?
          if @lhs.is_a? Rubex::AST::Expression
            @lhs.analyse_statement(local_scope)
          elsif local_scope.has_entry? @lhs
            @lhs = local_scope[@lhs]
          else
            # If LHS is not found in the symtab assume that its a Ruby object being assigned.
            local_scope.add_ruby_obj(name: @lhs, c_name: Rubex::VAR_PREFIX + @lhs,
              value: @rhs)
            @lhs = local_scope[@lhs]
            @ruby_obj_init = true
          end
        end

        def generate_code code, local_scope
          super
          if @lhs.is_a?(AST::Expression::ElementRef) && @lhs.type.object?
            generate_code_for_ruby_element_assign code, local_scope
          else
            generate_code_for_element_assign code, local_scope
          end
        end

        def generate_code_for_ruby_element_assign code, local_scope
          args = [@lhs.pos,@rhs].map do |arg|
            "#{arg.type.to_ruby_object(arg.c_code(local_scope))}"
          end.join(",")
          code << "rb_funcall(#{@lhs.entry.c_name}, rb_intern(\"[]=\"), 2, #{args});"
          code.nl
        end

        def generate_code_for_element_assign code, local_scope
          str = "#{@lhs.c_code(local_scope)} = "
          if @ruby_obj_init
            if @rhs.is_a?(Rubex::AST::Expression::Literal::Char)
              str << "#{@rhs.type.to_ruby_object(@rhs.c_code(local_scope), true)}"
            else
              str << "#{@rhs.type.to_ruby_object(@rhs.c_code(local_scope))}"
            end
          else
            if @lhs.type.cptr?
              if @lhs.type.type.char? && @rhs.type.object?
                # FIXME: This should happen only if object is declared as Ruby string.
                str << "StringValueCStr(#{@rhs.c_code(local_scope)})"
              else
                str << "#{@rhs.c_code(local_scope)}"
              end
            else
              str << "#{@rhs.c_code(local_scope)}"
            end
          end
          str << ";"
          code << str
          code.nl
        end
      end # class Assign

      class IfBlock
        module Helper
          def analyse_statement local_scope
            # binding.pry
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

        def initialize expr, statements, if_tail, location
          super(location)
          @expr, @statements, @if_tail = expr, statements, if_tail
        end

        def generate_code code, local_scope
          generate_code_for_statement "if", code, local_scope
        end

        class Elsif
          attr_reader :expr, :statements, :if_tail
          include Rubex::AST::Statement
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize expr, statements, if_tail, location
            super(location)
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

          def initialize statements, location
            super(location)
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

      class For
        include Rubex::AST::Statement
        attr_reader :left_expr, :left_op, :middle, :right_op, :right_expr,
                    :statements, :order

        def initialize left_expr, left_op, middle, right_op, right_expr,
          statements, location
          super(location)
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

        def initialize expr, statements, location
          super(location)
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

      class Alias
        include Rubex::AST::Statement
        attr_reader :new_name, :type, :old_name

        def initialize new_name, old_name, location
          super(location)
          @new_name, @old_name = new_name, old_name
          Rubex::CUSTOM_TYPES[@new_name] = @new_name
        end

        def analyse_statement local_scope, extern: false
          original = @old_name.gsub("struct ", "").gsub("union ", "")
          if !(Rubex::CUSTOM_TYPES.has_key?(original) ||
               Rubex::TYPE_MAPPINGS.has_key?(original))
            raise "Type #{original} has not been defined."
          end
          base_type =
          if Rubex::TYPE_MAPPINGS.has_key? original
            Rubex::TYPE_MAPPINGS[original].new
          else
            Rubex::CUSTOM_TYPES[original]
          end

          @type = Rubex::DataType::TypeDef.new(base_type, @new_name, base_type)
          Rubex::CUSTOM_TYPES[@new_name] = @type
          local_scope.declare_type self if original != @new_name
        end

        def generate_code code, local_scope

        end
      end # class Alias

      class Expression
        include Rubex::AST::Statement
        attr_reader :expr

        def initialize expr, location
          super(location)
          @expr = expr
        end

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
        end

        def generate_code code, local_scope
          super
          code << @expr.c_code(local_scope) + ";"
          code.nl
        end
      end # class Expression

      class CFunctionDecl
        include Rubex::AST::Statement
        attr_reader :entry

        def initialize type, name, arg_list
          @type, @name, @arg_list = type, name, arg_list
        end

        def analyse_statement local_scope, extern: false
          @arg_list.map! { |a| a.analyse_statement(local_scope); a.type }
          c_name = extern ? @name : (Rubex::C_FUNC_PREFIX + @name)
          type   = Rubex::DataType::CFunction.new(@name, c_name, @arg_list, 
            Helpers.determine_dtype(@type))
          @entry = local_scope.add_c_method(name: @name, c_name: c_name, type: type,
            extern: extern)
        end

        def generate_code code, local_scope
          super
          code << "# C function #{@name} declared." if @entry.extern?
        end
      end # class CFunctionDecl
    end # module Statement
  end # module AST
end # module Rubex
