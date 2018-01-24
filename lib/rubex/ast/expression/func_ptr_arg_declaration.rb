# Function argument is a function pointer.
module Rubex
  module AST
    module Expression

      class FuncPtrArgDeclaration < ArgDeclaration

        def analyse_types local_scope, extern: false
          var, dtype, ident, ptr_level, value = fetch_data
          cfunc_return_type = Helpers.determine_dtype(dtype, ident[:return_ptr_level])
          arg_list = ident[:arg_list].analyse_statement(local_scope)
          ptr_level = "*" if ptr_level.empty?
          name, c_name = ident[:name], Rubex::ARG_PREFIX + ident[:name]
          @type = Helpers.determine_dtype(
          DataType::CFunction.new(name, c_name, arg_list, cfunc_return_type, nil), ptr_level)
            add_arg_to_symbol_table name, c_name, @type, value, extern, local_scope
          end
        end # class FuncPtrArgDeclaration
      end
    end
  end
