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
        # TODO: Put error detection logic here.
        generate_preamble code
      end

     private

      def generate_preamble code
        code << ""
      end
    end
  end
end