module Rubex
  module AST
    module Expression

      class RubyHashElementRef < RubyObjectElementRef
        def generate_evaluation_code(code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = rb_hash_aref(#{@entry.c_name}, #{@pos.c_code(local_scope)});"
          @pos.generate_disposal_code code
        end

        def generate_assignment_code(rhs, code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          code << "rb_hash_aset(#{@entry.c_name}, #{@pos.c_code(local_scope)},"
          code << "#{rhs.c_code(local_scope)});"
          @pos.generate_disposal_code code
        end
      end # class RubyHashElementRef
    end
  end
end
