include Rubex::DataType

module Rubex
  module AST
    module Statement
      class Base
        include Rubex::Helpers::NodeTypeMethods

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
      end # class Base

      class CBaseType < Base
        attr_reader :type, :name, :value

        def initialize type, name, value=nil
          @type, @name, @value = type, name, value
        end

        def == other
          self.class == other.class &&
          self.type == other.class  &&
          self.name == other.name   &&
          self.value == other.value
        end

        def analyse_statement local_scope
          @type = Rubex::Helpers.determine_dtype @type
        end
      end # class CBaseType

      class VarDecl < Base
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
          @type = Helpers.determine_dtype @type, ""
          c_name = extern ? @name : Rubex::VAR_PREFIX + @name
          if @value
            @value.analyse_for_target_type(@type, local_scope)
            @value.allocate_temp local_scope, @value.type
            @value = Helpers.to_lhs_type(self, @value)
            @value.release_temp local_scope
          end

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
          if @value
            @value.generate_evaluation_code code, local_scope
            lhs = local_scope.find(@name).c_name
            code << "#{lhs} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end
      end # class VarDecl

      class CPtrDecl < Base
        attr_reader :entry, :type

        def initialize type, name, value, ptr_level, location
          super(location)
          @name, @type, @value, @ptr_level  = name, type, value, ptr_level
        end

        def analyse_statement local_scope, extern: false
          cptr_cname extern
          @type = Helpers.determine_dtype @type, @ptr_level
          if @value
            @value.analyse_for_target_type(@type, local_scope)
            @value = Helpers.to_lhs_type(self, @value)
          end

          @entry = local_scope.declare_var name: @name, c_name: @c_name,
            type: @type, value: @value, extern: extern
        end

        # FIXME: This feels jugaadu. Try to scan all declarations before you
        # scan individual statements.
        def rescan_declarations local_scope
          base_type = @entry.type.base_type
          if base_type.is_a? String
            type = Helpers.determine_dtype base_type, @ptr_level
            local_scope[@name].type = type
          end
        end

        def generate_code code, local_scope
          if @value
            @value.generate_evaluation_code code, local_scope
            code << "#{local_scope.find(@name).c_name} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end

        private

        def cptr_cname extern
           @c_name = extern ? @name : Rubex::POINTER_PREFIX + @name
        end
      end # class CPtrDecl

      class CPtrFuncDecl < CPtrDecl
        def initialize type, name, value, ptr_level, location
          super
        end
        
        def analyse_statement local_scope, extern: false
          cptr_cname extern
          ident = @type[:ident]
          ident[:arg_list].analyse_statement(local_scope)
          @type = DataType::CFunction.new(
            @name,
            @c_name,
            ident[:arg_list],
            Helpers.determine_dtype(@type[:dtype], ident[:return_ptr_level]),
            nil
          )
          super
        end
      end # class CPtrFuncDecl

      class CArrayDecl < Base
        attr_reader :type, :array_list, :name, :dimension

        def initialize type, array_ref, array_list, location
          super(location)
          @name, @array_list = array_ref.name, array_list
          @dimension = array_ref.pos
          @type = Rubex::TYPE_MAPPINGS[type].new
        end

        def analyse_statement local_scope, extern: false
          @dimension.analyse_types local_scope
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
            expr.analyse_types(local_scope)
          end
        end

        def verify_array_list_types local_scope
          @array_list.all? do |expr|
            return true if @type >= expr.type
            raise "Specified type #{@type} but list contains #{expr.type}."
          end
        end

        def create_symbol_table_entry local_scope
          local_scope.add_carray(name: @name, c_name: Rubex::ARRAY_PREFIX + @name,
            dimension: @dimension, type: @type, value: @array_list)
        end
      end # class CArrayDecl

      class CStructOrUnionDef < Base
        attr_reader :name, :declarations, :type, :kind, :entry, :scope

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
          @scope = Rubex::SymbolTable::Scope::StructOrUnion.new(
            @name, outer_scope)
          if extern
            c_name = @kind.to_s + " " + @name
          else
            c_name = Rubex::TYPE_PREFIX + @scope.klass_name + "_" + @name
          end
          @type = Rubex::DataType::CStructOrUnion.new(@kind, @name, c_name, 
            @scope)

          @declarations.each do |decl|
            decl.analyse_statement @scope, extern: extern
          end
          Rubex::CUSTOM_TYPES[@name] = @type
          @entry = outer_scope.declare_sue(name: @name, c_name: c_name,
            type: @type, extern: extern)
        end

        def generate_code code, local_scope=nil

        end

        def rescan_declarations local_scope
          @declarations.each do |decl|
            decl.respond_to?(:rescan_declarations) and
            decl.rescan_declarations(@scope)
          end
        end
      end # class CStructOrUnion

      class ForwardDecl < Base
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
          local_scope.declare_type type: @type, extern: extern
        end

        def rescan_declarations local_scope
          @type = Rubex::DataType::TypeDef.new("#{@kind} #{@name}", @c_name,
            Rubex::CUSTOM_TYPES[@name])
        end

        def generate_code code, local_scope

        end
      end # class ForwardDecl

      class Print < Base
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
            expr.analyse_types local_scope
            expr.allocate_temps local_scope
            expr.allocate_temp local_scope, expr.type
            expr.release_temps local_scope
            expr.release_temp local_scope
          end
        end

        def generate_code code, local_scope
          super
          @expressions.each do |expr|
            expr.generate_evaluation_code code, local_scope

            str = "printf("
            str << "\"#{expr.type.p_formatter}\""
            str << ", #{inspected_expr(expr, local_scope)}"
            str << ");"
            code << str
            code.nl

            expr.generate_disposal_code code
          end
          
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
      end # class Print

      class Return < Base
        attr_reader :expression, :type

        def initialize expression, location
          super(location)
          @expression = expression
        end

        def analyse_statement local_scope
          unless @expression
            if local_scope.type.ruby_method?
              @expression = Rubex::AST::Expression::Literal::Nil.new 'Qnil'
            elsif local_scope.type.c_function?
              @expression = Rubex::AST::Expression::Empty.new
            end # FIXME: print a warning for type mismatch if none of above 
          end

          @expression.analyse_types local_scope
          @expression.allocate_temps local_scope
          @expression.allocate_temp local_scope, @expression.type
          @expression.release_temps local_scope
          @expression.release_temp local_scope
          t = @expression.type

          @type =
          if t.c_function? || t.alias_type?
            t.type
          else
            t
          end
          @expression = @expression.to_ruby_object if local_scope.type.type.object?

          # TODO: Raise error if type as inferred from the
          # is not compatible with the return statement type.
        end

        def generate_code code, local_scope
          super
          @expression.generate_evaluation_code code, local_scope
          code << "return #{@expression.c_code(local_scope)};"
          code.nl
        end
      end # class Return

      class Assign < Base
        attr_reader :lhs, :rhs

        def initialize lhs, rhs, location
          super(location)
          @lhs, @rhs = lhs, rhs
        end

        def analyse_statement local_scope
          if @lhs.is_a?(Rubex::AST::Expression::Name)
            @lhs.analyse_declaration @rhs, local_scope
          else
            @lhs.analyse_types(local_scope)
          end
          @lhs.allocate_temps local_scope
          @lhs.allocate_temp local_scope, @lhs.type

          @rhs.analyse_for_target_type(@lhs.type, local_scope)
          @rhs = Helpers.to_lhs_type(@lhs, @rhs)

          @rhs.allocate_temps local_scope
          @rhs.allocate_temp local_scope, @rhs.type

          @lhs.release_temps local_scope
          @lhs.release_temp local_scope
          @rhs.release_temps local_scope
          @rhs.release_temp local_scope
        end

        def generate_code code, local_scope
          super
          @rhs.generate_evaluation_code code, local_scope
          @lhs.generate_assignment_code @rhs, code, local_scope
          @rhs.generate_disposal_code code
        end
      end # class Assign

      class IfBlock < Base
        module Helper
          def analyse_statement local_scope
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end

            @if_tail.analyse_statement(local_scope) if @if_tail
          end

          def generate_code_for_statement stat, code, local_scope, node
            if stat != "else"
              condition = node.expr.c_code(local_scope)
              expr_condition = node.expr.type.object? ? "RTEST(#{condition})" : condition
              code << "#{stat} (#{expr_condition}) "
            else
              code << "#{stat}"
            end

            code.block do
              node.statements.each do |stat|
                stat.generate_code code, local_scope
                code.nl
              end
            end

            if stat != "else"
              node.if_tail.generate_code(code, local_scope) if node.if_tail
            end
          end
        end # module Helper

        attr_reader :expr, :statements, :if_tail
        include Rubex::AST::Statement::IfBlock::Helper

        def initialize expr, statements, if_tail, location
          super(location)
          @expr, @statements, @if_tail = expr, statements, if_tail
        end

        def analyse_statement local_scope
          @tail_exprs = if_tail_exprs
          @tail_exprs.each do |tail|
            tail.analyse_types local_scope
            tail.allocate_temps local_scope
            tail.allocate_temp local_scope, tail.type
          end
          @tail_exprs.each do |tail|
            tail.release_temps local_scope
            tail.release_temp local_scope
          end
          super
        end

        def if_tail_exprs
          tail_exprs = []
          temp = self
          while temp.respond_to?(:if_tail) && 
            !temp.is_a?(Rubex::AST::Statement::IfBlock::Else)
            tail_exprs << temp.expr
            temp = temp.if_tail
          end

          tail_exprs
        end

        def generate_code code, local_scope
          @tail_exprs.each do |tail|
            tail.generate_evaluation_code(code, local_scope)
          end
          generate_code_for_statement "if", code, local_scope, self

          tail = @if_tail
          while tail
            if tail.is_a?(Elsif)
              generate_code_for_statement "else if", code, local_scope, tail
            elsif tail.is_a?(Else)
              generate_code_for_statement "else", code, local_scope, tail
            end
            tail = tail.if_tail
          end

          @tail_exprs.each do |tail|
            tail.generate_disposal_code code
          end
        end

        class Elsif < Base
          attr_reader :expr, :statements, :if_tail
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize expr, statements, if_tail, location
            super(location)
            @expr, @statements, @if_tail = expr, statements, if_tail
          end

          def generate_code code, local_scope
          end
        end # class Elsif

        class Else < Base
          attr_reader :statements
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
          end

          def if_tail; nil; end
        end # class Else
      end # class IfBlock

      class For < Base
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
          @left_expr.analyse_types local_scope
          @right_expr.analyse_types local_scope

          [ @left_expr, @right_expr ].each do |e|
            e.allocate_temps local_scope
            e.allocate_temp local_scope, e.type
          end
          [ @left_expr, @right_expr ].each do |e|
            e.release_temps local_scope
            e.release_temp local_scope
          end

          @middle = local_scope[@middle] # middle will not be an expr.
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          code << for_loop_header(code, local_scope)
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
          @left_expr.generate_disposal_code code
          @right_expr.generate_disposal_code code
        end

        private

        def for_loop_header code, local_scope
          @left_expr.generate_evaluation_code code, local_scope
          @right_expr.generate_evaluation_code code, local_scope
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

      class While < Base
        attr_reader :expr, :statements

        def initialize expr, statements, location
          super(location)
          @expr, @statements = expr, statements
        end

        def analyse_statement local_scope
          @expr.analyse_types local_scope
          @expr.allocate_temp local_scope, @expr.type
          @expr.release_temp local_scope
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
        end

        def generate_code code, local_scope
          @expr.generate_evaluation_code code, local_scope
          stmt = "while (#{@expr.c_code(local_scope)})"
          code << stmt
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
          @expr.generate_disposal_code code
        end
      end # class While

      class Alias < Base
        attr_reader :new_name, :type, :old_name

        def initialize new_name, old_name, location
          super(location)
          @new_name, @old_name = new_name, old_name
          Rubex::CUSTOM_TYPES[@new_name] = @new_name
        end

        def analyse_statement local_scope, extern: false
          original  = @old_name[:dtype].gsub("struct ", "").gsub("union ", "")
          var       = @old_name[:variables][0]
          ident     = var[:ident]
          ptr_level = var[:ptr_level]

          base_type =
          if ident.is_a?(Hash) # function pointer
            cfunc_return_type = Helpers.determine_dtype(original,
              ident[:return_ptr_level])
            arg_list = ident[:arg_list].analyse_statement(local_scope)
            ptr_level = "*" if ptr_level.empty?

            Helpers.determine_dtype(
              DataType::CFunction.new(nil, nil, arg_list, cfunc_return_type, nil),
              ptr_level
            )
          else
            Helpers.determine_dtype(original, ptr_level)
          end

          @type = Rubex::DataType::TypeDef.new(base_type, @new_name, base_type)
          Rubex::CUSTOM_TYPES[@new_name] = @type
          local_scope.declare_type(type: @type, extern: extern) if original != @new_name
        end

        def generate_code code, local_scope

        end
      end # class Alias

      class Expression < Base
        attr_reader :expr
        attr_accessor :typecast

        def initialize expr, location
          super(location)
          @expr = expr
        end

        def analyse_statement local_scope
          @expr.analyse_types local_scope
          @expr.allocate_temps local_scope
          @expr.allocate_temp local_scope, @expr.type
        end

        def generate_code code, local_scope
          super
          @expr.generate_evaluation_code code, local_scope
          code << @expr.c_code(local_scope) + ";"
          code.nl
          @expr.generate_disposal_code code
        end
      end # class Expression

      class CFunctionDecl < Base
        attr_reader :entry

        def initialize type, return_ptr_level, name, arg_list
          @type, @return_ptr_level, @name, @arg_list = type, return_ptr_level, 
            name, arg_list
        end

        def analyse_statement local_scope, extern: false
          @arg_list.analyse_statement(local_scope, extern: extern) if @arg_list
          c_name = extern ? @name : (Rubex::C_FUNC_PREFIX + @name)
          # type   = Rubex::DataType::CFunction.new(@name, c_name, @arg_list, 
          #   Helpers.determine_dtype(@type, @return_ptr_level), nil)
          @entry = local_scope.add_c_method(
            name: @name,
            c_name: c_name,
            return_type: Helpers.determine_dtype(@type, @return_ptr_level),
            arg_list: @arg_list,
            scope: nil,
            extern: extern)
        end

        def generate_code code, local_scope
          super
          code << "/* C function #{@name} declared.*/" if @entry.extern?
        end
      end # class CFunctionDecl

      # This node is used for both formal and actual arguments of functions/methods.
      class ArgumentList < Base
        include Enumerable

        # args - [ArgDeclaration]
        attr_reader :args

        def each &block
          @args.each(&block)
        end

        def map! &block
          @args.map!(&block)
        end

        def pop
          @args.pop
        end

        def initialize args
          @args = args
        end

        def analyse_statement local_scope, extern: false
          @args.each do |arg|
            arg.analyse_types(local_scope, extern: extern)
          end
        end

        def push arg
          @args << arg
        end

        def << arg
          push arg
        end

        def == other
          self.class == other.class && @args == other.args
        end

        def size
          @args.size
        end

        def empty?
          @args.empty?
        end

        def [] idx
          @args[idx]
        end
      end # class ArgumentList

      
      # FIXME: this probably is an expression?
      class ActualArgList < ArgumentList
        def analyse_statement local_scope
          @args.each do |arg|
            arg.analyse_types local_scope
          end
        end

        def allocate_temps local_scope
          @args.each { |a| a.allocate_temp(local_scope, a.type) }
        end

        def release_temps local_scope
          @args.each { |a| a.release_temp(local_scope) }
        end

        def generate_evaluation_code code, local_scope
          @args.each do |a|
            a.generate_evaluation_code code, local_scope
          end
        end

        def generate_disposal_code code
          @args.each do |a|
            a.generate_disposal_code code
          end
        end
      end # class ActualArgList

      class Raise < Base
        def initialize args
          @args = args
        end

        def analyse_statement local_scope
          @args.analyse_statement local_scope
          @args.allocate_temps local_scope
          @args.release_temps local_scope
          unless @args.empty? || @args[0].is_a?(AST::Expression::Name) ||
            @args[0].is_a?(AST::Expression::Literal::StringLit)
            raise Rubex::TypeMismatchError, "Wrong argument list #{@args.inspect} for raise."
          end
        end

        def generate_code code, local_scope
          @args.generate_evaluation_code code, local_scope
          str = ""
          str << "rb_raise("

          if @args[0].is_a?(AST::Expression::Name)
            str << @args[0].c_code(local_scope) + ','
            args = @args[1..-1]
          else
            str << Rubex::DEFAULT_CLASS_MAPPINGS["RuntimeError"] + ','
            args = @args
          end

          unless args.empty?
            str << "\"#{prepare_format_string(args)}\" ,"
            str << args.map { |arg| "#{inspected_expr(arg, local_scope)}" }.join(',')
          else
            str << "\"\""
          end
          str << ");"
          code << str
          code.nl
          @args.generate_disposal_code code
        end

      private

        def prepare_format_string args
          format_string = ""
          args.each do |expr|
            format_string << expr.type.p_formatter
          end

          format_string
        end

        def inspected_expr expr, local_scope
          obj = expr.c_code(local_scope)
          if expr.type.object?
            "RSTRING_PTR(rb_funcall(#{obj}, rb_intern(\"inspect\"), 0, NULL))"
          else
            obj
          end  
        end
      end # class Raise

      class Break < Base
        def analyse_statement local_scope
          # TODO: figure whether this is a Ruby break or C break. For now
          #   assuming C break.
        end

        def generate_code code, local_scope
          code.write_location @location
          code << "break;"
          code.nl
        end
      end # class Break

      class Yield < Base
        def initialize args
          @args = args
        end

        def analyse_statement local_scope
          @args = @args.map do |arg|
            arg.analyse_types local_scope
            arg.allocate_temps local_scope
            arg.allocate_temp local_scope, arg.type
            arg.to_ruby_object
          end

          @args.each do |arg|
            arg.release_temps local_scope
            arg.release_temp local_scope
          end
        end

        def generate_code code, local_scope
          @args.each do |a|
            a.generate_evaluation_code code, local_scope
          end

          if @args.size > 0
            code << "rb_yield_values(#{@args.size}, "
            code << "#{@args.map { |a| a.c_code(local_scope) }.join(',')}"
            code << ");"
          else
            code << "rb_yield(Qnil);"
          end
          code.nl

          @args.each do |a|
            a.generate_disposal_code code
          end
        end
      end # class Yield

      module BeginBlock
        class Base < Statement::Base
          attr_reader :statements

          def initialize statements, location
            @statements = statements
            super(location)
          end
        end # class Base

        class Begin < Base
          def initialize statements, tails, location
            @tails = tails
            super(statements, location)
          end

          def analyse_statement local_scope
            local_scope.found_begin_block
            declare_error_state_variable local_scope
            declare_error_klass_variable local_scope
            declare_unhandled_error_variable local_scope
            @block_scope = Rubex::SymbolTable::Scope::BeginBlock.new(
              block_name(local_scope), local_scope)
            create_c_function_to_house_statements local_scope.outer_scope
            analyse_tails local_scope
          end

          def generate_code code, local_scope
            code.nl
            code << "/* begin-rescue-else-ensure-end block begins: */"
            code.nl
            super
            cb_c_name = local_scope.find(@begin_func.name).c_name
            state_var = local_scope.find(@state_var_name).c_name
            code << "#{state_var} = 0;\n"
            code << "rb_protect(#{cb_c_name}, Qnil, &#{state_var});"
            code.nl
            generate_rescue_else_ensure code, local_scope
          end

        private

          def generate_rescue_else_ensure code, local_scope
            err_state_var = local_scope.find(@error_var_name).c_name
            set_error_state_variable err_state_var, code, local_scope
            set_unhandled_error_variable code, local_scope
            generate_rescue_blocks err_state_var, code, local_scope
            generate_else_block code, local_scope
            generate_ensure_block code, local_scope
            generate_rb_jump_tag err_state_var, code, local_scope
            code << "rb_set_errinfo(Qnil);\n"
          end

          def declare_unhandled_error_variable local_scope
            @unhandled_err_var_name = "begin_block_" + local_scope.begin_block_counter.to_s + "_unhandled_error"
            local_scope.declare_var(
              name: @unhandled_err_var_name,
              c_name: Rubex::VAR_PREFIX + @unhandled_err_var_name,
              type: DataType::Int.new
            )            
          end

          def set_unhandled_error_variable code, local_scope
            n = local_scope.find(@unhandled_err_var_name).c_name
            code << "#{n} = 0;"
            code.nl
          end

          def generate_rb_jump_tag err_state_var, code, local_scope
            state_var = local_scope.find(@state_var_name).c_name
            code << "if (#{local_scope.find(@unhandled_err_var_name).c_name})"
            code.block do
              code << "rb_jump_tag(#{state_var});"
              code.nl
            end
          end

          def generate_ensure_block code, local_scope
            ensure_block = @tails.select { |e| e.is_a?(Ensure) }[0]
            ensure_block.generate_code(code, local_scope) unless ensure_block.nil?
          end

          # We use a goto statement to jump to the ensure block so that when a
          # condition arises where no error is raised, the ensure statement will
          # be executed, after which rb_jump_tag() will be called.
          def generate_else_block code, local_scope
            else_block = @tails.select { |t| t.is_a?(Else) }[0]
            
            code << "else"
            code.block do
                state_var = local_scope.find(@state_var_name).c_name
                code << "/* If exception not among those captured in raise */"
                code.nl

                code << "if (#{state_var})"
                code.block do
                  code << "#{local_scope.find(@unhandled_err_var_name).c_name} = 1;"
                  code.nl
                end

              if else_block
                code << "else"
                code.block do
                  else_block.generate_code code, local_scope
                end 
              end
            end
          end

          def set_error_state_variable err_state_var, code, local_scope
            code << "#{err_state_var} = rb_errinfo();"
            code.nl
          end

          def generate_rescue_blocks err_state_var, code, local_scope
            if @tails[0].is_a?(Rescue)
              generate_first_rescue_block err_state_var, code, local_scope
              
              @tails[1..-1].grep(Rescue).each do |resc|
                else_if_cond = rescue_condition err_state_var, resc, code, local_scope
                code << "else if (#{else_if_cond})"
                code.block do
                  resc.generate_code code, local_scope
                end
              end
            else # no rescue blocks present
              code << "if (0) {}\n"
            end   
          end

          def generate_first_rescue_block err_state_var, code, local_scope
            code << "if (#{rescue_condition(err_state_var, @tails[0], code, local_scope)})"
            code.block do
              @tails[0].generate_code code, local_scope
            end
          end

          def rescue_condition err_state_var, resc, code, local_scope
            resc.error_klass.generate_evaluation_code code, local_scope
            cond = "RTEST(rb_funcall(#{err_state_var}, rb_intern(\"kind_of?\")"
            cond << ", 1, #{resc.error_klass.c_code(local_scope)}))"

            cond
          end

          def declare_error_state_variable local_scope
            @state_var_name = "begin_block_" + local_scope.begin_block_counter.to_s + "_state"
            local_scope.declare_var(
              name: @state_var_name,
              c_name: Rubex::VAR_PREFIX + @state_var_name,
              type: DataType::Int.new
            )
          end

          def declare_error_klass_variable local_scope
            @error_var_name = "begin_block_" + local_scope.begin_block_counter.to_s + "_exec"
            local_scope.declare_var(
              name: @error_var_name,
              c_name: Rubex::VAR_PREFIX + @error_var_name,
              type: DataType::RubyObject.new
            )
          end

          def block_name local_scope
            "begin_block_" + local_scope.klass_name + "_" + local_scope.name + "_" +
              local_scope.begin_block_counter.to_s
          end

          def create_c_function_to_house_statements scope
            func_name = @block_scope.name
            arg_list = Statement::ArgumentList.new([
                AST::Expression::ArgDeclaration.new(
                  { dtype:'object', variables: [{ident: 'dummy'}]})
              ])
            @begin_func = TopStatement::CFunctionDef.new(
              'object', '', func_name, arg_list, @statements) 
            arg_list.analyse_statement @block_scope
            add_to_symbol_table @begin_func.name, arg_list, scope
            @begin_func.analyse_statement @block_scope
            @block_scope.upgrade_symbols_to_global
            scope.add_begin_block_callback @begin_func
          end

          def add_to_symbol_table func_name, arg_list, scope
            c_name = Rubex::C_FUNC_PREFIX + func_name
            scope.add_c_method(
              name: func_name, 
              c_name: c_name, 
              extern: false,
              return_type: DataType::RubyObject.new,
              arg_list: arg_list,
              scope: @block_scope
            )
          end

          def analyse_tails local_scope
            @tails.each do |tail|
              tail.analyse_statement local_scope
            end
          end
        end # class Begin

        class Else < Base
          def analyse_statement local_scope
            @statements.each do |stmt|
              stmt.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope
            @statements.each do |stmt|
              stmt.generate_code code, local_scope
            end
          end
        end # class Else

        class Rescue < Base
          attr_reader :error_klass

          def initialize error_klass, error_obj, statements, location
            super(statements, location)
            @error_klass, @error_obj = error_klass, error_obj
          end

          def analyse_statement local_scope
            @error_klass.analyse_types local_scope
            if !@error_klass.type.ruby_constant?
              raise "Must pass an error class to raise. Location #{@location}."
            end

            @statements.each do |stmt|
              stmt.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope
            @statements.each do |stmt|
              stmt.generate_code code, local_scope
            end
          end
        end # class Rescue

        class Ensure < Base
          def analyse_statement local_scope
            @statements.each do |stmt|
              stmt.analyse_statement local_scope
            end
          end

          def generate_code code, local_scope
            @statements.each do |stmt|
              stmt.generate_code code, local_scope
            end
          end
        end # class Ensure
      end # module BeginBlock
    end # module Statement
  end # module AST
end # module Rubex
