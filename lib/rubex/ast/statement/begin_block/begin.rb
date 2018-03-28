module Rubex
  module AST
    module Statement
      module BeginBlock
        class Begin < Base
          def initialize(statements, tails, location)
            @tails = tails
            super(statements, location)
          end

          def analyse_statement(local_scope)
            local_scope.found_begin_block
            declare_error_state_variable local_scope
            declare_error_klass_variable local_scope
            declare_unhandled_error_variable local_scope
            @block_scope = Rubex::SymbolTable::Scope::BeginBlock.new(
              block_name(local_scope), local_scope
            )
            create_c_function_to_house_statements local_scope.outer_scope
            analyse_tails local_scope
          end

          def generate_code(code, local_scope)
            code.nl
            code << '/* begin-rescue-else-ensure-end block begins: */'
            code.nl
            super
            cb_c_name = local_scope.find(@begin_func.name).c_name
            state_var = local_scope.find(@state_var_name).c_name
            code << "#{state_var} = 0;\n"
            code << "rb_protect(#{cb_c_name}, Qnil, &#{state_var});"
            code.nl
            generate_rescue_else_ensure code, local_scope
          end

          private

          def generate_rescue_else_ensure(code, local_scope)
            err_state_var = local_scope.find(@error_var_name).c_name
            set_error_state_variable err_state_var, code, local_scope
            set_unhandled_error_variable code, local_scope
            generate_rescue_blocks err_state_var, code, local_scope
            generate_else_block code, local_scope
            generate_ensure_block code, local_scope
            generate_rb_jump_tag err_state_var, code, local_scope
            code << "rb_set_errinfo(Qnil);\n"
          end

          def declare_unhandled_error_variable(local_scope)
            @unhandled_err_var_name = 'begin_block_' + local_scope.begin_block_counter.to_s + '_unhandled_error'
            local_scope.declare_var(
              name: @unhandled_err_var_name,
              c_name: Rubex::VAR_PREFIX + @unhandled_err_var_name,
              type: DataType::Int.new
            )
          end

          def set_unhandled_error_variable(code, local_scope)
            n = local_scope.find(@unhandled_err_var_name).c_name
            code << "#{n} = 0;"
            code.nl
          end

          def generate_rb_jump_tag(_err_state_var, code, local_scope)
            state_var = local_scope.find(@state_var_name).c_name
            code << "if (#{local_scope.find(@unhandled_err_var_name).c_name})"
            code.block do
              code << "rb_jump_tag(#{state_var});"
              code.nl
            end
          end

          def generate_ensure_block(code, local_scope)
            ensure_block = @tails.select { |e| e.is_a?(Ensure) }[0]
            ensure_block&.generate_code(code, local_scope)
          end

          # We use a goto statement to jump to the ensure block so that when a
          # condition arises where no error is raised, the ensure statement will
          # be executed, after which rb_jump_tag() will be called.
          def generate_else_block(code, local_scope)
            else_block = @tails.select { |t| t.is_a?(Else) }[0]

            code << 'else'
            code.block do
              state_var = local_scope.find(@state_var_name).c_name
              code << '/* If exception not among those captured in raise */'
              code.nl

              code << "if (#{state_var})"
              code.block do
                code << "#{local_scope.find(@unhandled_err_var_name).c_name} = 1;"
                code.nl
              end

              if else_block
                code << 'else'
                code.block do
                  else_block.generate_code code, local_scope
                end
              end
            end
          end

          def set_error_state_variable(err_state_var, code, _local_scope)
            code << "#{err_state_var} = rb_errinfo();"
            code.nl
          end

          def generate_rescue_blocks(err_state_var, code, local_scope)
            if @tails[0].is_a?(Rescue)
              generate_first_rescue_block err_state_var, code, local_scope

              @tails[1..-1].grep(Rescue).each do |resc|
                else_if_cond = rescue_condition err_state_var, resc, code, local_scope
                code << "else if (#{else_if_cond})"
                code.block do
                  resc.generate_code code, local_scope
                end
              end
            else # no rescue blocks present
              code << "if (0) {}\n"
            end
          end

          def generate_first_rescue_block(err_state_var, code, local_scope)
            code << "if (#{rescue_condition(err_state_var, @tails[0], code, local_scope)})"
            code.block do
              @tails[0].generate_code code, local_scope
            end
          end

          def rescue_condition(err_state_var, resc, code, local_scope)
            resc.error_klass.generate_evaluation_code code, local_scope
            cond = "RTEST(rb_funcall(#{err_state_var}, rb_intern(\"kind_of?\")"
            cond << ", 1, #{resc.error_klass.c_code(local_scope)}))"

            cond
          end

          def declare_error_state_variable(local_scope)
            @state_var_name = 'begin_block_' + local_scope.begin_block_counter.to_s + '_state'
            local_scope.declare_var(
              name: @state_var_name,
              c_name: Rubex::VAR_PREFIX + @state_var_name,
              type: DataType::Int.new
            )
          end

          def declare_error_klass_variable(local_scope)
            @error_var_name = 'begin_block_' + local_scope.begin_block_counter.to_s + '_exec'
            local_scope.declare_var(
              name: @error_var_name,
              c_name: Rubex::VAR_PREFIX + @error_var_name,
              type: DataType::RubyObject.new
            )
          end

          def block_name(local_scope)
            'begin_block_' + local_scope.klass_name + '_' + local_scope.name + '_' +
              local_scope.begin_block_counter.to_s
          end
          
          def create_c_function_to_house_statements(scope)
            func_name = @block_scope.name
            arg_list = Statement::ArgumentList.new([
                                                     AST::Expression::ArgDeclaration.new(
                                                     { dtype: 'object',
                                                       variables: [{ ident: 'dummy' }] }
                                                     )
                                                   ])
            @begin_func = TopStatement::CFunctionDef.new(
              'object', '', func_name, arg_list, nil, @statements
            )
            arg_list.analyse_statement @block_scope
            add_to_symbol_table @begin_func.name, arg_list, scope
            @begin_func.analyse_statement @block_scope
            @block_scope.upgrade_symbols_to_global
            scope.add_begin_block_callback @begin_func
          end

          def add_to_symbol_table(func_name, arg_list, scope)
            c_name = Rubex::C_FUNC_PREFIX + func_name
            scope.add_c_method(
              name: func_name,
              c_name: c_name,
              extern: false,
              return_type: DataType::RubyObject.new,
              arg_list: arg_list,
              scope: @block_scope
            )
          end

          def analyse_tails(local_scope)
            @tails.each do |tail|
              tail.analyse_statement local_scope
            end
          end
        end
      end
    end
  end
end
