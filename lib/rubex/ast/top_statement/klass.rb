module Rubex
  module AST
    module TopStatement
      class Klass
        include Rubex::Helpers::Writers
        # Stores the scope of the class. Rubex::SymbolTable::Scope::Klass.
        attr_reader :scope

        attr_reader :name

        attr_reader :ancestor

        attr_reader :statements

        attr_reader :entry

        # Name of the class. Ancestor can be Scope::Klass or String object
        #   depending on whether invoker is another higher level scope or
        #   the parser. Statements are the statements inside the class.
        def initialize(name, ancestor, statements)
          @name = name
          @ancestor = ancestor
          @statements = statements
          @ancestor = 'Object' if @ancestor.nil?
        end

        def analyse_statement(local_scope, attach_klass: false)
          @entry = local_scope.find(@name)
          @scope = @entry.type.scope
          @ancestor = @entry.type.ancestor
          add_statement_symbols_to_symbol_table
          unless attach_klass
            @statements.each do |stat|
              stat.analyse_statement @scope
            end
          end
        end

        def rescan_declarations(_local_scope)
          @statements.each do |stat|
            stat&.rescan_declarations(@scope)
          end
        end

        def generate_code(code)
          @scope.begin_block_callbacks.each do |cb|
            cb.generate_code code
          end

          @scope.no_gil_block_callbacks.each do |cb|
            cb.generate_code code
          end

          @statements.each do |stat|
            stat.generate_code code
          end
        end

        protected

        def add_statement_symbols_to_symbol_table
          @statements.each do |stmt|
            next unless ruby_method_or_c_function?(stmt)
            f_name, f_scope = prepare_name_and_scope_of_functions(stmt)
            next if auxillary_c_function_for_attached_klass?(f_name)
            stmt.arg_list.analyse_statement(f_scope)
            if stmt.is_a? Rubex::AST::TopStatement::RubyMethodDef
              add_ruby_method_to_scope f_name, f_scope, stmt.arg_list
            elsif stmt.is_a? Rubex::AST::TopStatement::CFunctionDef
              return_type = Helpers.determine_dtype(stmt.type, stmt.return_ptr_level)
              add_c_function_to_scope f_name, f_scope, stmt.arg_list, return_type
            end
          end
        end

        def auxillary_c_function_for_attached_klass?(f_name)
          is_a?(AttachedKlass) && [
            Rubex::ALLOC_FUNC_NAME, Rubex::DEALLOC_FUNC_NAME,
            Rubex::MEMCOUNT_FUNC_NAME, Rubex::GET_STRUCT_FUNC_NAME
          ].include?(f_name)
        end

        def add_c_function_to_scope(f_name, f_scope, arg_list, return_type)
          c_name = c_func_c_name(f_name)
          arg_list.each do |arg|
            if arg.entry&.value
              e = arg.entry
              e.value = Rubex::Helpers.to_lhs_type(e, e.value)
            end
          end
          @scope.add_c_method(
            name: f_name,
            c_name: c_name,
            extern: false,
            return_type: return_type,
            arg_list: arg_list,
            scope: f_scope
          )
        end

        def add_ruby_method_to_scope(f_name, f_scope, arg_list)
          c_name = Rubex::RUBY_FUNC_PREFIX + @name + '_' +
                   f_name.gsub('?', '_qmark').gsub('!', '_bang')
          @scope.add_ruby_method(
            name: f_name,
            c_name: c_name,
            scope: f_scope,
            arg_list: arg_list
          )
        end

        def prepare_name_and_scope_of_functions(stmt)
          f_name = stmt.name
          f_scope = Rubex::SymbolTable::Scope::Local.new f_name, @scope
          [f_name, f_scope]
        end

        def ruby_method_or_c_function?(stmt)
          stmt.is_a?(Rubex::AST::TopStatement::RubyMethodDef) ||
            stmt.is_a?(Rubex::AST::TopStatement::CFunctionDef)
        end

        def c_func_c_name(name)
          Rubex::C_FUNC_PREFIX + @name + '_' + name
        end
      end
    end
  end
end
