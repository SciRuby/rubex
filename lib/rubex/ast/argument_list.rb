module Rubex
  module AST
    class ArgumentList
      include Enumerable
      attr_reader :args

      def each &block
        @args.each(&block)
      end

      def initialize
        @args = []
      end

      def push arg
        @args << arg
      end
    end
  end
end
