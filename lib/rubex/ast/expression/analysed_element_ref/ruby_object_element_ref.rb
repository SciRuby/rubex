module Rubex
  module AST
    module Expression
      class RubyObjectElementRef < AnalysedElementRef
        def analyse_types(local_scope)
          super
          @has_temp = true
          @pos = @pos.to_ruby_object
          @subexprs << @pos
        end

        def generate_evaluation_code(code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          code << "#{@c_code} = rb_funcall(#{@entry.c_name}, rb_intern(\"[]\"), 1, "
          code << "#{@pos.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end

        def generate_disposal_code(code)
          code << "#{@c_code} = 0;"
          code.nl
        end

        def generate_element_ref_code(expr, code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          str = "#{@c_code} = rb_funcall(#{expr.c_code(local_scope)}."
          str << "#{@entry.c_name}, rb_intern(\"[]\"), 1, "
          str << "#{@pos.c_code(local_scope)});"
          code << str
          code.nl
          @pos.generate_disposal_code code
        end

        def generate_assignment_code(rhs, code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          code << "rb_funcall(#{@entry.c_name}, rb_intern(\"[]=\"), 2,"
          code << "#{@pos.c_code(local_scope)}, #{rhs.c_code(local_scope)});"
          code.nl
          @pos.generate_disposal_code code
        end
      end
    end
  end
end
