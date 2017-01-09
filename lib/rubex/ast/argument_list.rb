module Rubex
  module AST
    class ArgumentList
      include Enumerable
      attr_reader :args

      def each &block
        @args.each(&block)
      end

      def initialize args
        @args = args
      end

      def push arg
        @args << arg
      end

      def == other
        self.class == other.class && @args == other.args
      end

      def size
        @args.size
      end

      def empty?
        @args.empty?
      end
    end
  end
end
