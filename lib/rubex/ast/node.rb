module Rubex
  module AST
    class Node
      attr_reader :children

      def initialize children
        @children = children.is_a?(Array) ? children : [children]
      end

      def add_child child
        @children << child
      end
    end
  end
end