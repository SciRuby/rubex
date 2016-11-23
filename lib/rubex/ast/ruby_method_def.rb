module Rubex
  module AST
    class RubyMethodDef
      attr_reader :name, :args, :statements, :c_name
      
      def initialize name, args
        @name, @args = name, args
        @c_name = Rubex::FUNC_PREFIX + name
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