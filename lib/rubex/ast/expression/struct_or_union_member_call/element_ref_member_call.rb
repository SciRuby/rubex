module Rubex
  module AST
    module Expression
      class ElementRefMemberCall < StructOrUnionMemberCall
        def analyse_types(local_scope, struct_scope)
          @command.analyse_types local_scope, struct_scope
          @type = @command.type
          @has_temp = @command.has_temp
          allocate_and_release_temps local_scope
        end

        def generate_evaluation_code(code, local_scope)
          @command.generate_element_ref_code @expr, code, local_scope
        end

        def c_code(local_scope)
          @command.c_code(local_scope)
        end
      end
    end
  end
end
