module Rubex
  module AST
    module Statement
      class Alias < Base
        def initialize(new_name, old_name, location)
          super(location)
          @new_name = new_name
          @old_name = old_name
          Rubex::CUSTOM_TYPES[@new_name] = @new_name
        end

        def analyse_statement(local_scope, extern: false)
          original  = @old_name[:dtype].gsub('struct ', '').gsub('union ', '')
          var       = @old_name[:variables][0]
          ident     = var[:ident]
          ptr_level = var[:ptr_level]

          base_type =
            if ident.is_a?(Hash) # function pointer
              cfunc_return_type = Helpers.determine_dtype(original,
                                                          ident[:return_ptr_level])
              arg_list = ident[:arg_list].analyse_statement(local_scope)
              ptr_level = '*' if ptr_level.empty?

              Helpers.determine_dtype(
                DataType::CFunction.new(nil, nil, arg_list, cfunc_return_type, nil),
                ptr_level
              )
            else
              Helpers.determine_dtype(original, ptr_level)
            end

          @type = Rubex::DataType::TypeDef.new(base_type, @new_name, base_type)
          Rubex::CUSTOM_TYPES[@new_name] = @type
          local_scope.declare_type(type: @type, extern: extern) if original != @new_name
        end

        def generate_code(code, local_scope); end
      end
    end
  end
end

