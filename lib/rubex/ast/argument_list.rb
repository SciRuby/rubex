module Rubex
  module AST
    class ArgumentList
      attr_reader :args

      def initialize
        @args = []
      end

      def push arg
        @args << arg
      end
    end
  end
end
