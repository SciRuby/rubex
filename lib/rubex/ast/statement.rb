module Rubex
  module AST
    class Statement
      class Return
        attr_reader :expression, :return_type

        def initialize expression
          @expression = expression
        end

        def analyse_expression local_scope
          case @expression
          when Rubex::AST::Expression::Addition
            left  = @expression.left
            right = @expression.right
          end

          left_type = local_scope[left].type
          right_type = local_scope[right].type

          @return_type = result_type_for left_type, right_type
        end

       private

        def result_type_for left_type, right_type
          dtype = Rubex::DataType

          if left_type.is_a?(dtype::CInt32) && right_type.is_a?(dtype::CInt32)
            return dtype::CInt32.new
          end
        end
      end
    end
  end
end