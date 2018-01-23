module Rubex
  module AST
    module Expression

      class Binary < Base
        include Rubex::Helpers::NodeTypeMethods

        attr_reader :operator
        attr_accessor :left, :right
        # Final return type of expression
        attr_accessor :type, :subexprs

        def initialize left, operator, right
          @left, @operator, @right = left, operator, right
          @@analyse_visited = []
          @subexprs = []
        end

        def analyse_types local_scope
          analyse_left_and_right_nodes local_scope, self
          analyse_return_type local_scope, self
          super
        end

        def allocate_temps local_scope
          @subexprs.each do |expr|
            if expr.is_a?(Binary)
              expr.allocate_temps local_scope
            else
              expr.allocate_temp local_scope, expr.type
            end
          end
        end

        def generate_evaluation_code code, local_scope
          @left.generate_evaluation_code code, local_scope
          @right.generate_evaluation_code code, local_scope
        end

        def generate_disposal_code code
          @left.generate_disposal_code code
          @right.generate_disposal_code code
        end

        def c_code local_scope
          code = super
          code << "( "
          left_code = @left.c_code(local_scope)
          right_code = @right.c_code(local_scope)
          if type_of(@left).object? || type_of(@right).object?
            left_ruby_code = @left.type.to_ruby_object(left_code)
            right_ruby_code = @right.type.to_ruby_object(right_code)

            if ["&&", "||"].include?(@operator)
              code << Rubex::C_MACRO_INT2BOOL +
              "(RTEST(#{left_ruby_code}) #{@operator} RTEST(#{right_ruby_code}))"
            else
              code << "rb_funcall(#{left_ruby_code}, rb_intern(\"#{@operator}\") "
              code << ", 1, #{right_ruby_code})"
            end
          else
            code << "#{left_code} #{@operator} #{right_code}"
          end
          code << " )"

          code
        end

        def == other
          self.class == other.class && @type  == other.type &&
          @left == other.left  && @right == other.right &&
          @operator == other.operator
        end

        private

        def type_of expr
          t = expr.type
          return (t.c_function? ? t.type : t)
        end

        def analyse_left_and_right_nodes local_scope, tree
          if tree.respond_to?(:left)
            analyse_left_and_right_nodes local_scope, tree.left

            if !@@analyse_visited.include?(tree.left.object_id)
              if tree.right.type
                tree.left.analyse_for_target_type(tree.right.type, local_scope)
              else
                tree.left.analyse_types(local_scope)
              end
              @subexprs << tree.left
              @@analyse_visited << tree.left.object_id
            end

            if !@@analyse_visited.include?(tree.right.object_id)
              if tree.left.type
                tree.right.analyse_for_target_type(tree.left.type, local_scope)
              else
                tree.right.analyse_types(local_scope)
              end
              @subexprs << tree.right
              @@analyse_visited << tree.right.object_id
            end

            @@analyse_visited << tree.object_id

            analyse_left_and_right_nodes local_scope, tree.right
          end
        end

        def analyse_return_type local_scope, tree
          if tree.respond_to? :left
            analyse_return_type local_scope, tree.left
            analyse_return_type local_scope, tree.right

            if ['==', '<', '>', '<=', '>=', '||', '&&', '!='].include? tree.operator
              if type_of(tree.left).object? || type_of(tree.right).object?
                tree.type = Rubex::DataType::Boolean.new
              else
                tree.type = Rubex::DataType::CBoolean.new
              end
            else
              if tree.left.type.bool? || tree.right.type.bool?
                raise Rubex::TypeMismatchError, "Operation #{tree.operator} cannot"\
                "be performed between #{tree.left} and #{tree.right}"
              end
              tree.type = Rubex::Helpers.result_type_for(
                type_of(tree.left), type_of(tree.right))
              end
            end
          end
        end
      end
    end
  end
