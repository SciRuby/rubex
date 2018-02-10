module Rubex
  module AST
    module Expression
      class RubyArrayElementRef < RubyObjectElementRef
        def analyse_types(local_scope)
          @has_temp = true
          @pos.analyse_types local_scope
          @subexprs << @pos
        end
        
        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "#{@c_code} = RARRAY_AREF(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
            code.nl
          end
        end
      end
    end
  end
end
