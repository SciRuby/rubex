module Rubex
  module AST
    class Statement
      class Return
        attr_reader :expression

        def initialize expression
          @expression = expression
        end
      end
    end
  end
end