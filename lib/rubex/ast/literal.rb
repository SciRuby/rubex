module Rubex
  module AST
    module Literal
      attr_reader :literal
      def initialize literal
        @literal = literal
      end

      class Double; include Rubex::AST::Literal;  end

      class Int;  include Rubex::AST::Literal;  end

      class Str; include Rubex::AST::Literal;  end

      class Char; include Rubex::AST::Literal;  end
    end
  end
end
