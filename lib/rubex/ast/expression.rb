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
          analyse_return_type local_scope, self
        end

        def generate_code
          code = ""
          recursive_generate_code(code, self)
          code
        end

      private

        def analyse_return_type local_scope, expr_tree
          if tree.respond_to? :left
            analyse_return_type local_scope, expr_tree.left

            if tree.left.is_a?(Rubex::AST::Expression) &&
               tree.right.is_a?(Rubex::AST::Expression)

            end
          end
        end

        def recursive_generate_code code, tree
          if tree.respond_to? :left
            inorder_traverse code, tree.left
            if tree.left.is_a?(Rubex::AST::Expression) && 
               tree.right.is_a?(Rubex::AST::Expression)
              code << "#{tree.operator}"
            else
              code << "(#{tree.left} #{tree.operator} #{tree.right})"
            end
            inorder_traverse code, tree.right
          end
        end
      end
    end
  end
end
