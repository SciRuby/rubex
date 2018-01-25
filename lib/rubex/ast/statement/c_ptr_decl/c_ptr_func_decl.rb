module Rubex
  module AST
    module Statement
      class CPtrFuncDecl < CPtrDecl
        def initialize(type, name, value, ptr_level, location)
          super
        end

        def analyse_statement(local_scope, extern: false)
          cptr_cname extern
          ident = @type[:ident]
          ident[:arg_list].analyse_statement(local_scope)
          @type = DataType::CFunction.new(
            @name,
            @c_name,
            ident[:arg_list],
            Helpers.determine_dtype(@type[:dtype], ident[:return_ptr_level]),
            nil
          )
          super
        end
      end
    end
  end
end
