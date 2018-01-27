module Rubex
  module AST
    module Expression
      class BinaryBooleanSpecialOp < BinaryBoolean
        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            if @has_temp
              code << "#{@c_code} = " + Rubex::C_MACRO_INT2BOOL +
                "(RTEST(#{@left.c_code(local_scope)}) #{@operator} " \
                "RTEST(#{@right.c_code(local_scope)}));"
              code.nl
            else
              @c_code = "#{@left.c_code(local_scope)} #{@operator} #{@right.c_code(local_scope)}"
            end
          end
        end
      end
    end
  end
end
