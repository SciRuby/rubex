module Rubex
  module AST
    module Statement
      class NoGilBlock < Base
        def initialize statements
          @statements = statements
        end

        def analyse_statement(local_scope)
          local_scope.found_no_gil_block
          @block_scope = Rubex::SymbolTable::Scope::NoGilBlock.new(
            block_name(local_scope), local_scope)
          create_c_function_to_house_statements local_scope.outer_scope
          # TODO: check if ruby objects exist in the block. Raise error if yes.
        end

        def generate_code(code, local_scope)
          code.nl
          code << "/* no_gil block: */"
          code.nl
          super
          cb_c_name = local_scope.find(@no_gil_func.name).c_name
          code << "rb_thread_call_without_gvl(#{cb_c_name}, NULL, RUBY_UBF_PROCESS, NULL);"
          code.nl
        end

        private

        def block_name(local_scope)
          "no_gil_block_" + local_scope.klass_name + "_" + local_scope.name + "_" +
            local_scope.no_gil_block_counter.to_s
        end

        def create_c_function_to_house_statements(outer_scope)
          func_name = @block_scope.name
          arg_list = Statement::ArgumentList.new([
                                                   AST::Expression::ArgDeclaration.new(
                                                   {
                                                     dtype: 'void',
                                                     variables:
                                                       [{
                                                          ptr_level: "*",
                                                          ident: 'dummy'
                                                        }]
                                                   })
                                                 ])
          @no_gil_func = TopStatement::CFunctionDef.new(
            'void', '*', func_name, arg_list, nil, @statements)
          arg_list.analyse_statement @block_scope
          add_to_symbol_table @no_gil_func.name, arg_list, outer_scope
          @no_gil_func.analyse_statement @block_scope
          @block_scope.upgrade_symbols_to_global
          outer_scope.add_no_gil_block_callback @no_gil_func
        end

        def add_to_symbol_table(func_name, arg_list, outer_scope)
          c_name = Rubex::C_FUNC_PREFIX + func_name
          outer_scope.add_c_method(
            name: func_name,
            c_name: c_name,
            extern: false,
            return_type: DataType::RubyObject.new,
            arg_list: arg_list,
            scope: @block_scope
          )
        end
      end
    end
  end
end
