module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        ap statements
        @statements = statements.is_a?(Array) ? statements : [statements]
      end

      def add_child child
        @statements.concat child
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object'
        generate_symbol_table_entries
        analyse_expressions
        generate_preamble code
      end

      # Pretty print the AST
      def pp
        # TODO
      end

     private

      def generate_preamble code
        code << "#include <ruby.h>\n"
        code << "#include <stdint.h>\n"
        code << "\n"
      end

      def generate_symbol_table_entries
        @statements.each do |stat|
          stat.generate_symbol_table_entries @scope
        end
      end

      def analyse_expressions
        @statements.each do |stat|
          stat.analyse_expressions @scope
        end
      end
    end
  end
end