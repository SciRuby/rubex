module Rubex
  module AST
    module Expression
      class RubyMethodCall < MethodCall
        def analyse_types(local_scope)
          super
          @type = Rubex::DataType::RubyObject.new
          prepare_arg_list(local_scope) if !@entry.extern? && !@arg_list.empty?
        end

        def c_code(local_scope)
          code = super
          code << code_for_ruby_method_call(local_scope)
          code
        end

        private

        def prepare_arg_list(local_scope)
          @arg_list_var = @entry.c_name + Rubex::ACTUAL_ARGS_SUFFIX
          args_size = @entry.type.arg_list&.size || 0
          local_scope.add_carray(name: @arg_list_var, c_name: @arg_list_var,
                                 dimension: Literal::Int.new(args_size.to_s),
                                 type: @type)
        end

        def code_for_ruby_method_call(local_scope)
          str = ''
          if @entry.extern?
            str << "rb_funcall(#{@invoker.c_code(local_scope)}, "
            str << "rb_intern(\"#{@method_name}\"), "
            str << @arg_list.size.to_s
            @arg_list.each do |arg|
              str << " ,#{arg.type.to_ruby_object(arg.c_code(local_scope))}"
            end
            str << ', NULL' if @arg_list.empty?
            str << ')'
          else
            str << populate_method_args_into_value_array(local_scope)
            str << actual_ruby_method_call(local_scope)
          end
          str
        end

        def actual_ruby_method_call(local_scope)
          str = "#{@entry.c_name}(#{@arg_list.size}, #{@arg_list_var || 'NULL'},"
          str << "#{local_scope.self_name})"
        end

        def populate_method_args_into_value_array(local_scope)
          str = ''
          @arg_list.each_with_index do |arg, idx|
            str = "#{@arg_list_var}[#{idx}] = "
            str << arg.type.to_ruby_object(arg.c_code(local_scope)).to_s
            str << ";\n"
          end

          str
        end
      end
    end
  end
end
