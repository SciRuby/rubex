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
          @c_name = extern ? @name : Rubex::VAR_PREFIX + @name
          if @value
            @value.analyse_for_target_type(@type, local_scope)
            @value = Helpers.to_lhs_type(self, @value)
          end

          local_scope.declare_var name: @name, c_name: @c_name, type: @type,
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
            code << "#{@c_name} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end
      end

      class CPtrDecl < Base
        attr_reader :entry, :type

        # type - Specifies the type of the pointer. Is a string in case of a
        # normal pointer denoting the data type and pointer level (like `int`
        # for a pointerto an integer). Can be a Hash in case of func pointer
        # declaration.
        # name [String] - name of the variable.
        def initialize type, name, value, ptr_level, location
          super(location)
          @name, @type, @value, @ptr_level  = name, type, value, ptr_level
        end

        def analyse_statement local_scope, extern: false
          @c_name = extern ? @name : Rubex::POINTER_PREFIX + @name
          
          if @type.is_a?(Hash) # function ptr
            ident = @type[:ident]
            ident[:arg_list].analyse_statement(local_scope, inside_func_ptr: true)
            @type = DataType::CFunction.new(@name, @c_name, ident[:arg_list],
              Helpers.determine_dtype(@type[:dtype], ident[:return_ptr_level]))
          end
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
            code << "#{@c_name} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end
      end

      class CArrayDecl < Base
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
            expr.analyse_statement(local_scope)
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
      end

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
            expr.analyse_statement local_scope
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

          @expression.analyse_statement local_scope
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
            @lhs.analyse_statement(local_scope)
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
            tail.analyse_statement local_scope
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
          @left_expr.analyse_statement local_scope
          @right_expr.analyse_statement local_scope

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
          @expr.analyse_statement local_scope
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
            arg_list = ident[:arg_list].analyse_statement(local_scope,
              inside_func_ptr: true)
            ptr_level = "*" if ptr_level.empty?

            Helpers.determine_dtype(
              DataType::CFunction.new(nil, nil, arg_list, cfunc_return_type),
              ptr_level)
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
          @expr.analyse_statement local_scope
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
          type   = Rubex::DataType::CFunction.new(@name, c_name, @arg_list, 
            Helpers.determine_dtype(@type, @return_ptr_level))
          @entry = local_scope.add_c_method(name: @name, c_name: c_name, type: type,
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

        def pop
          @args.pop
        end

        def initialize args
          @args = args
        end

        # func_ptr - switch that determines if this ArgList is part of the
        # argument list of an argument that is a function pointer.
        # For eg - 
        #   cfunc int foo(int (*bar)(int, float)).
        #                            ^^^ This is an arg list inside a function.
        def analyse_statement local_scope, inside_func_ptr: false, extern: false
          @args.each do |arg|
            arg.analyse_statement(local_scope, inside_func_ptr: inside_func_ptr,
              extern: extern)
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

      class ActualArgList < ArgumentList
        def analyse_statement local_scope
          @args.each do |arg|
            arg.analyse_statement local_scope
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
            arg.analyse_statement local_scope
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
      end
    end # module Statement
  end # module AST
end # module Rubex
