module Rubex
  module AST
    module Expression
      class BinaryBooleanSpecialOp < BinaryBoolean
        def generate_evaluation_code(code, local_scope)
          @left.generate_evaluation_code code, local_scope
          @right.generate_evaluation_code code, local_scope
          @c_code = Rubex::C_MACRO_INT2BOOL +
                    "(RTEST(#{@left.c_code(local_scope)}) #{@operator} " \
                    "RTEST(#{@right.c_code(local_scope)}))"
        end
      end
    end
  end
end
