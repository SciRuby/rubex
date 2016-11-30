module Rubex
  module AST
    module Statement
      class VariableDeclaration
        include Rubex::AST::Statement
        attr_reader :dtype, :name, :c_name, :value

        def initialize dtype, name, value=nil
          unless Rubex::TYPE_MAPPINGS.has_key?(dtype)
            raise "Dtype #{dtype} is not supported."
          end

          @dtype, @name, @value = Rubex::TYPE_MAPPINGS[dtype].new, name, value
          @c_name = Rubex::VAR_PREFIX + name
        end

        def analyse_expression local_scope
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
        end
      end

      class Print
        include Rubex::AST::Statement
        attr_reader :expression, :print_type

        def initialize expression
          @expression = expression
        end

        def analyse_expression local_scope
          if @expression.is_a? String
            entry = local_scope[@expression]
          elsif @expression.class.to_s =~ "Rubex::AST::Expression"
            # TODO: Determine print type of expression.
          end

          

        end
      end
      
      class Return
        include Rubex::AST::Statement
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
          # TODO: Raise error if return_type is not compatible with the return
          # type of the function.
        end

        def generate_code code, local_scope
          code << "return "
          case @expression
          when Rubex::AST::Expression::Addition
            left  = @expression.left
            right = @expression.right
            code << @return_type.to_ruby_function( 
              "#{local_scope[left].c_name} + #{local_scope[right].c_name}")
            code << ";"
            code.new_line
          end
        end

       private

        def result_type_for left_type, right_type
          dtype = Rubex::DataType

          if left_type.is_a?(dtype::Int32) && right_type.is_a?(dtype::Int32)
            return dtype::Int32.new
          end
        end
      end
    end
  end
end