module Rubex
  module AST
    module Expression
      class RubyArrayElementRef < RubyObjectElementRef
        def generate_evaluation_code code, local_scope
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = RARRAY_AREF(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end
      end # class RubyArrayElementRef
    end
  end
end
