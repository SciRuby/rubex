module Rubex
  module AST
    module Expression
      class CVarElementRef < AnalysedElementRef
        def analyse_types(local_scope)
          @pos.analyse_types local_scope
        end

        def generate_evaluation_code(code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          @c_code = "#{@entry.c_name}[#{@pos.c_code(local_scope)}]"
        end

        def generate_element_ref_code(_expr, code, local_scope)
          generate_evaluation_code code, local_scope
        end

        def generate_assignment_code(rhs, code, local_scope)
          @pos.generate_evaluation_code code, local_scope
          code << "#{@entry.c_name}[#{@pos.c_code(local_scope)}] = "
          code << "#{rhs.c_code(local_scope)};"
          @pos.generate_disposal_code code
        end
      end # class CVarElementRef
    end
  end
end
