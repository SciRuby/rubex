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
      attr_reader :return_type
      
      def initialize name, args, statements
        @name, @args = name, args
        @c_name = Rubex::FUNC_PREFIX + name
        @statements = []
        statements.each { |s| @statements << s }
        @return_type = Rubex::DataType::RubyObject.new
      end

      def generate_symbol_table_entries outer_scope
        @scope = Rubex::SymbolTable::Scope::Local.new
        @scope.outer_scope = outer_scope
        @scope.return_type = @return_type.dup
        @scope.declare_args @args
      end

      def analyse_expressions outer_scope
        @statements.each do |stat|
          stat.analyse_expression @scope
        end
      end

      def generate_code code
        code.write_func_declaration @return_type.to_s, @c_name
        code.write_func_definition_header @return_type.to_s, @c_name
        generate_function_definition code
        code << "}"
      end

    private

      def generate_function_definition code
        declare_args code
        generate_arg_checking code
        init_args code
        generate_statements code
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

      def init_args code
        @scope.arg_entries.each_with_index do |arg, i|
          code << arg.c_name + '=' + arg.type.from_ruby_function("argv[#{i}]")
          code << ";"
          code.nl
        end
      end

      def generate_arg_checking code
        code << 'if (argc != ' + @scope.arg_entries.size.to_s + ")\n"
        code << "{\n"
        code << %Q{rb_raise(rb_eArgError, "Need #{@scope.arg_entries.size} args, not %d", argc);\n}
        code << "}\n"
      end
    end
  end
end