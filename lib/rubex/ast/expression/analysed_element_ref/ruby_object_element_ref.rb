module Rubex
  module AST
    module Expression
      class RubyObjectElementRef < AnalysedElementRef
        def analyse_types(local_scope)
          super
          @has_temp = true
          @pos = @pos.to_ruby_object
          @pos.allocate_temps local_scope
          @pos.release_temps local_scope
          @subexprs << @pos
        end

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "#{@c_code} = rb_funcall(#{@entry.c_name}, rb_intern(\"[]\"), 1, "
            code << "#{@pos.c_code(local_scope)});"
            code.nl
          end
        end

        def generate_element_ref_code(expr, code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            str = "#{@c_code} = rb_funcall(#{expr.c_code(local_scope)}."
            str << "#{@entry.c_name}, rb_intern(\"[]\"), 1, "
            str << "#{@pos.c_code(local_scope)});"
            code << str
            code.nl
          end
        end

        def generate_assignment_code(rhs, code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            code << "rb_funcall(#{@entry.c_name}, rb_intern(\"[]=\"), 2,"
            code << "#{@pos.c_code(local_scope)}, #{rhs.c_code(local_scope)});"
            code.nl
          end
        end
      end
    end
  end
end
