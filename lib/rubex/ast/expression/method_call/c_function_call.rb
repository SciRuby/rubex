module Rubex
  module AST
    module Expression
      class CFunctionCall < MethodCall
        def analyse_types(local_scope)
          @entry = local_scope.find(@method_name)
          super
          append_self_argument if  !@entry.extern? && !@entry.no_gil
          @type = @entry.type.base_type
          @arg_list.analyse_for_target_type @type.arg_list, local_scope
          @arg_list.allocate_temps local_scope
          @arg_list.release_temps local_scope

          type_check_arg_types @entry
        end

        def generate_evaluation_code code, local_scope
          super
          @c_code = code_for_c_method_call local_scope
        end

        def c_code(local_scope)
          @c_code
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
