module Rubex
  module AST
    class Node
      attr_reader :child

      def initialize g
        @g = g
      end
    end
  end
end