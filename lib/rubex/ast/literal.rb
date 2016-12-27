module Rubex
  module AST
    module Literal
      include Rubex::Helpers::NodeTypeMethods
      attr_reader :literal

      def initialize literal
        @literal = literal
      end

      def c_code local_scope
        @literal
      end

      def literal?; true; end

      class Double
        include Rubex::AST::Literal

        def type
          Rubex::DataType::F64.new
        end
      end

      class Int
        include Rubex::AST::Literal

        def type
          Rubex::DataType::Int.new
        end
      end

      # class Str; include Rubex::AST::Literal;  end

      class Char
        include Rubex::AST::Literal

        def type
          Rubex::DataType::Char.new
        end
      end
    end
  end
end
