module Rubex
  module AST
    module Expression
      class CFunctionCall < MethodCall
        def analyse_types(local_scope)
          super
          @type = @entry.type.base_type
          append_self_argument unless @entry.extern?
          type_check_arg_types @entry
        end

        def c_code(local_scope)
          code = super
          code << code_for_c_method_call(local_scope)
          code
        end

        private

        def append_self_argument
          @arg_list << Expression::Self.new
        end

        def code_for_c_method_call(local_scope)
          str = "#{@entry.c_name}("
          str << @arg_list.map { |a| a.c_code(local_scope) }.join(',')
          str << ')'
          str
        end
      end
    end
  end
end
