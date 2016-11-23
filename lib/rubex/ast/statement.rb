module Rubex
  module AST
    class Statement
      class Return
        attr_reader :expression, :return_type

        def initialize expression
          @expression = expression
        end
      end
    end
  end
end