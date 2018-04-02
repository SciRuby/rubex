module Rubex
  module AST
    module Expression
      class RubyArrayElementRef < RubyObjectElementRef
        def analyse_types(local_scope)
          @has_temp = true
          @pos.analyse_types local_scope
          @subexprs << @pos
        end

        # FIXME: If there are multiple arguments specified for array_ref,
        #   we cannot use RARRAY_REF.
        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "#{@c_code} = RARRAY_AREF(#{@entry.c_name},"
            code << "#{@pos[0].c_code(local_scope)});"
            code.nl
          end
        end
      end
    end
  end
end
