module Rubex
  module AST
    module TopStatement
      class CFunctionDef < MethodDef
        attr_reader :type, :return_ptr_level

        def initialize(type, return_ptr_level, name, arg_list, function_tags, statements)
          super(name, arg_list, statements)
          @type = type
          @return_ptr_level = return_ptr_level
          @function_tags = function_tags
        end

        def analyse_statement(outer_scope, extern: false)
          if @function_tags == "no_gil"
            @no_gil = true
          end
          super(outer_scope)
        end

        def generate_code(code)
          code.write_c_method_header(type: @entry.type.type.to_s,
                                     c_name: @entry.c_name, args: Helpers.create_arg_arrays(@arg_list))
          super code, c_function: true
        end
      end

    end
  end
end
