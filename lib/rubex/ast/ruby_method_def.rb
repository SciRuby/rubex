module Rubex
  module AST
    class RubyMethodDef
      # Ruby name of the method.
      attr_reader :name
      # The equivalent C name of the method.
      attr_reader :c_name
      # Method arguments.
      attr_reader :args
      # The statments/expressions contained within the method.
      attr_reader :statements
      # Symbol Table entry.
      attr_reader :entry
      # Return type of the function.
      attr_reader :type

      def initialize name, args, statements
        @name, @args = name, args
        @c_name = Rubex::FUNC_PREFIX + name
        @statements = []
        statements.each { |s| @statements << s }
        @type = Rubex::DataType::RubyObject.new
      end

      def generate_symbol_table_entries outer_scope
        @scope = Rubex::SymbolTable::Scope::Local.new
        @scope.outer_scope = outer_scope
        @scope.type = @type.dup
        @scope.declare_args @args

        variables = @statements.select do |s|
          s.is_a?(Rubex::AST::Statement::VariableDeclaration)
        end
        @scope.declare_vars variables
      end

      def analyse_statements outer_scope
        @statements.each do |stat|
          stat.analyse_statement @scope
        end
      end

      def generate_code code
        code.write_func_declaration @type.to_s, @c_name
        code.write_func_definition_header @type.to_s, @c_name
        code.block do
          generate_function_definition code
        end
      end

      def == other
        self.class == other.class && @name == other.name &&
        @c_name == other.c_name && @args == other.args &&
        @statements == other.statements && @entry == other.entry &&
        @type == other.type
      end

    private

      def generate_function_definition code
        declare_args code
        declare_vars code
        declare_ruby_objects code
        generate_arg_checking code
        init_args code
        init_vars code
        generate_statements code
      end

      def declare_ruby_objects code
        @scope.ruby_obj_entries.each do |var|
          code.declare_variable var
        end
      end

      def generate_statements code
        @statements.each do |stat|
          stat.generate_code code, @scope
        end
      end

      def declare_args code
        @scope.arg_entries.each do |arg|
          code.declare_variable arg
        end
      end

      def declare_vars code
        @scope.var_entries.each do |var|
          code.declare_variable var
        end
      end

      def init_args code
        @scope.arg_entries.each_with_index do |arg, i|
          code << arg.c_name + '=' + arg.type.from_ruby_function("argv[#{i}]")
          code << ";"
          code.nl
        end
      end

      def init_vars code
        @scope.var_entries.select { |v| v.value }.each do |var|
          code.init_variable var, @scope
        end
      end

      def generate_arg_checking code
        code << 'if (argc != ' + @scope.arg_entries.size.to_s + ")"
        code.block do
          code << %Q{rb_raise(rb_eArgError, "Need #{@scope.arg_entries.size} args, not %d", argc);\n}
        end
      end
    end
  end
end
