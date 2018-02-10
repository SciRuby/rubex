module Rubex
  module AST
    module Expression
      class RubyMethodCall < MethodCall        
        def analyse_types(local_scope)
          @entry = local_scope.find(@method_name)
          add_as_ruby_method_to_symtab(local_scope) unless @entry
          super
          @arg_list.analyse_types local_scope
          @type = Rubex::DataType::RubyObject.new
          @arg_list.map! { |a| a.to_ruby_object }
          @arg_list.allocate_temps local_scope
          @arg_list.release_temps local_scope
          prepare_arg_list(local_scope) if !@entry.extern? && !@arg_list.empty?
          @has_temp = true
        end

        def generate_evaluation_code code, local_scope
          super
          code_for_ruby_method_call code, local_scope
        end

        def c_code(local_scope)
          @c_code
        end

        private

        def add_as_ruby_method_to_symtab(local_scope)
          @entry = local_scope.add_ruby_method(
            name: @method_name,
            c_name: @method_name,
            extern: true,
            arg_list: @arg_list,
            scope: nil
          )
        end

        def prepare_arg_list(local_scope)
          @arg_list_var = @entry.c_name + Rubex::ACTUAL_ARGS_SUFFIX
          args_size = @entry.type.arg_list&.size || 0
          local_scope.add_carray(name: @arg_list_var, c_name: @arg_list_var,
                                 dimension: Literal::Int.new(args_size.to_s),
                                 type: @type)
        end

        def code_for_ruby_method_call(code, local_scope)
          str = "#{@c_code} = "
          if @entry.extern?
            str << "rb_funcall(#{@invoker.c_code(local_scope)}, "
            str << "rb_intern(\"#{@method_name}\"), "
            str << @arg_list.size.to_s
            @arg_list.each do |arg|
              str << " ,#{arg.c_code(local_scope)}"
            end
            str << ', NULL' if @arg_list.empty?
            str << ");\n"
          else
            str << populate_method_args_into_value_array(local_scope)
            str << actual_ruby_method_call(local_scope)
          end
          code << str
        end

        def actual_ruby_method_call(local_scope)
          str = "#{@entry.c_name}(#{@arg_list.size}, #{@arg_list_var || 'NULL'},"
          str << "#{local_scope.self_name});"
        end

        def populate_method_args_into_value_array(local_scope)
          str = ''
          @arg_list.each_with_index do |arg, idx|
            str = "#{@arg_list_var}[#{idx}] = "
            str << arg.c_code(local_scope).to_s
            str << ";\n"
          end

          str
        end
      end
    end
  end
end
