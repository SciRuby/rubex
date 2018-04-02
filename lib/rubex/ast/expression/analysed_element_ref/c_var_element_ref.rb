module Rubex
  module AST
    module Expression
      class CVarElementRef < AnalysedElementRef
        def analyse_types(local_scope)
          if @pos.size > 1
            raise "C array can only accept 1 arg. Not #{@pos.size}"
          end
          @pos.analyse_types local_scope
          @subexprs << @pos
        end

        def generate_evaluation_code(code, local_scope)
          generate_and_dispose_subexprs(code, local_scope) do
            @c_code = "#{@entry.c_name}[#{@pos[0].c_code(local_scope)}]"
          end
        end

        def generate_element_ref_code(_expr, code, local_scope)
          generate_evaluation_code code, local_scope
        end

        def generate_assignment_code(rhs, code, local_scope)
         generate_and_dispose_subexprs(code, local_scope) do
            code << "#{@entry.c_name}[#{@pos[0].c_code(local_scope)}] = "
            code << "#{rhs.c_code(local_scope)};"
            code.nl
          end
        end
      end
    end
  end
end
