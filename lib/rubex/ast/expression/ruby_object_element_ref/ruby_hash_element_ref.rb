module Rubex
  module AST
    module Expression
      class RubyHashElementRef < RubyObjectElementRef
        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "#{@c_code} = rb_hash_aref(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
            code.nl
          end
        end

        def generate_assignment_code(rhs, code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "rb_hash_aset(#{@entry.c_name}, #{@pos.c_code(local_scope)},"
            code << "#{rhs.c_code(local_scope)});"
            code.nl
          end
        end
      end
    end
  end
end
