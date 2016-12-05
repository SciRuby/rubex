module Rubex
  module AST
    module Statement
      class VariableDeclaration
        include Rubex::AST::Statement
        attr_reader :type, :name, :c_name, :value

        def initialize type, name, value=nil
          unless Rubex::TYPE_MAPPINGS.has_key?(type)
            raise "type #{type} is not supported."
          end

          @type, @name, @value = Rubex::TYPE_MAPPINGS[type].new, name, value
          @c_name = Rubex::VAR_PREFIX + name
        end

        def analyse_expression local_scope
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
        end

        def generate_code code, local_scope
          
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
            raise "Invalid expression #{@expression} to print." unless entry
            @print_type = entry.type
          elsif @expression.class.to_s =~ "Rubex::AST::Expression"
            # TODO: Determine print type of expression.
          end
        end

        def generate_code code, local_scope
          entry = local_scope[@expression]
          type = entry.type

          code.new_line
          code << type.printf(entry.c_name)
          code.new_line
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
          # TODO: Raise error if return_type as inferred from the
          # is not compatible with the return statement type.
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
          type = Rubex::DataType

          if left_type.class == right_type.class
            return left_type.class.new
          end
        end
      end
    end
  end
end