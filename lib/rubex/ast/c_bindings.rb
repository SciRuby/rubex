module Rubex
  module AST
    class CBindings
      include Rubex::AST::Statement
      attr_reader :lib, :declarations

      def initialize lib, declarations
        @lib, @declarations = lib, declarations
      end

      def analyse_statements local_scope
        @declarations.each do |stat|
          stat.analyse_statement local_scope, extern: true
        end
      end

      class CFunctionDecl
        include Rubex::AST::Statement
        attr_reader :type, :name, :args

        def initialize type, name, args
          @type, @name, @args = type, name, args
        end
      end # class CFunctionDecl
    end # class CBindings
  end
end
