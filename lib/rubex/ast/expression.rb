module Rubex
  module AST
    module Expression
      class Binary
        include Rubex::AST::Expression
        include Rubex::Helpers::NodeTypeMethods

        attr_reader :operator
        attr_accessor :left, :right
        # Final return type of expression
        attr_accessor :type

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
        end

        def analyse_statement local_scope
          analyse_left_and_right_nodes local_scope, self
          analyse_return_type local_scope, self
        end

        def c_code local_scope
          code = ""
          recursive_generate_code(local_scope, code, self)
          code
        end

        def expression?; true; end

      private

        def analyse_left_and_right_nodes local_scope, tree
          if tree.respond_to?(:left)
            analyse_left_and_right_nodes local_scope, tree.left
            if local_scope.has_entry? tree.left
              tree.left = local_scope[tree.left]
            end

            if local_scope.has_entry? tree.right
              tree.right = local_scope[tree.right]
            end
            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left

            if ['==', '<', '>', '<=', '>='].include? tree.operator
              tree.type = Rubex::DataType::Boolean.new
            else
              tree.type = Rubex::Helpers.result_type_for(
                     tree.left.type, tree.right.type)
            end

            analyse_return_type local_scope, tree.right
          end
        end

        def recursive_generate_code local_scope, code, tree
          if tree.respond_to? :left
            recursive_generate_code local_scope, code, tree.left

            if !tree.left.is_a?(Rubex::AST::Expression)
              if !tree.right.is_a?(Rubex::AST::Expression)
                code << "("
              end
              code << "#{tree.left.c_name}"
            end

            code << " #{tree.operator} "

            if !tree.right.is_a?(Rubex::AST::Expression)
              code << "#{tree.right.c_name}"
              if !tree.left.is_a?(Rubex::AST::Expression)
                code << ")"
              end
            end
            recursive_generate_code local_scope, code, tree.right
          end
        end
      end
    end
  end
end
