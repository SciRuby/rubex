module Rubex
  module AST
    module Expression

      # Function argument is the argument of a function pointer.
      class FuncPtrInternalArgDeclaration < ArgDeclaration
        def analyse_types local_scope, extern: false
          var, dtype, ident, ptr_level, value = fetch_data
          @type = Helpers.determine_dtype(dtype, ptr_level)
        end
      end # class FuncPtrInternalArgDeclaration
    end
  end
end
