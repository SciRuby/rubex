module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        @statements = statements.is_a?(Array) ? statements : [statements]
      end

      def add_child child
        @statements << child
      end

      def process_statements target_name, code
        generate_preamble code
      end

     private

      def generate_preamble code
        code << "#include <ruby.h>"
        code << "\n"

      end
    end
  end
end