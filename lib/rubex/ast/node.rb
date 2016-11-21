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
        
      end
    end
  end
end