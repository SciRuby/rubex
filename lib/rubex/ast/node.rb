module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        ap statements
        @statements = statements.is_a?(Array) ? statements : [statements]
      end

      def add_child child
        ap child
        @statements.concat child
      end

      def process_statements target_name, code
        generate_preamble code
        generate_symbol_table_entries
      end

      def pp
        h = {}
        # h["Node"] = 
      end

     private

      def generate_preamble code
        code << "#include <ruby.h>"
        code << "\n"
      end

      def generate_symbol_table_entries
        @scope = Rubex::SymbolTable::Scope::Klass.new :Object
        @statements.each do |stat|

        end

      end
    end
  end
end