module Rubex
  module AST
    class MethodDef
      attr_reader :method_name, :args, :statements
      
      def initialize method_name, args
        @method_name, @args = method_name, args
        @statements = []
      end

      def add_statements statements
        statements.each { |s| @statements << s }
      end

      def process_statements
        
      end
    end
  end
end