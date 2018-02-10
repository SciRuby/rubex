module Rubex
  module AST
    module Statement
      class CFunctionDecl < Base
        def initialize(type, return_ptr_level, name, arg_list)
          @type, @return_ptr_level, @name, @arg_list = type, return_ptr_level,
          name, arg_list
        end

        def analyse_statement(local_scope, extern: false)
          @arg_list&.analyse_statement(local_scope, extern: extern)
          c_name = extern ? @name : (Rubex::C_FUNC_PREFIX + @name)
          @entry = local_scope.add_c_method(
            name: @name,
            c_name: c_name,
            return_type: Helpers.determine_dtype(@type, @return_ptr_level),
            arg_list: @arg_list,
            scope: nil,
            extern: extern
          )
        end

        def generate_code(code, local_scope)
          super
          code << "/* C function #{@name} declared.*/" if @entry.extern?
        end
      end
    end
  end
end
