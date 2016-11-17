module Rubex
  module AST
    class MethodDef
      attr_reader :method_name, :args, :statements
      
      def initialize method_name, args, statements
        @method_name, @args, @statements = method_name, args, statements
      end
    end
  end
end