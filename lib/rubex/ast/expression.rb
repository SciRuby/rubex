module Rubex
  module AST
    module Expression
      class Binary
        include Rubex::AST::Expression
        
        attr_reader :left, :operator, :right, :return_type

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
        end

        def analyse_expression local_scope
          # TODO: analyse expression for dtype compatibility.
        end

        def generate_code
          "#{@left} #{@operator} #{@right}"
        end
      end
    end
  end
end
