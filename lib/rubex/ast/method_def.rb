module Rubex
  module AST
    class MethodDef
      attr_reader :name, :args, :statements, :c_name
      
      def initialize name, args
        @name, @args = name.to_sym, args
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