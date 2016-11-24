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
      
      def initialize name, args
        @name, @args = name, args
        @c_name = Rubex::FUNC_PREFIX + name
        @statements = []
        @return_type = Rubex::DataType::RubyObject.new
      end

      def add_statements statements
        statements.each { |s| @statements << s }
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

      def generate_function_definition code
        
      end
    end
  end
end