module Rubex
  module AST
    module TopStatement
      class AttachedKlass < Klass
        attr_reader :attached_type

        ALLOC_FUNC_NAME      = Rubex::ALLOC_FUNC_NAME
        DEALLOC_FUNC_NAME    = Rubex::DEALLOC_FUNC_NAME
        MEMCOUNT_FUNC_NAME   = Rubex::MEMCOUNT_FUNC_NAME
        GET_STRUCT_FUNC_NAME = Rubex::GET_STRUCT_FUNC_NAME

        def initialize(name, attached_type, ancestor, statements, location)
          @attached_type = attached_type
          @location = location
          super(name, ancestor, statements)
        end

        def analyse_statement(outer_scope)
          super(outer_scope, attach_klass: true)
          prepare_data_holding_struct
          prepare_rb_data_type_t_struct
          detach_and_modify_auxillary_c_functions_from_statements
          add_auxillary_functions_to_klass_scope
          prepare_auxillary_c_functions
          @statements[1..-1].each do |stmt| # 0th stmt is the data struct
            if ruby_method_or_c_func?(stmt)
              rewrite_method_with_data_fetching stmt
            end
            stmt.analyse_statement @scope
          end
          analyse_auxillary_c_functions
        end

        def generate_code(code)
          write_auxillary_c_functions code
          write_data_type_t_struct code
          write_get_struct_c_function code
          write_alloc_c_function code
          super
        end

        private

        # Since auxillary functions are detached from the klass statements,
        #   analyse their arg_list separately and add function names to the
        #   class scope so that their statements can be analysed properly later.
        def add_auxillary_functions_to_klass_scope
          @auxillary_c_functions.each_value do |func|
            f_name, f_scope = prepare_name_and_scope_of_functions func
            func.arg_list.analyse_statement(f_scope)
            return_type = Helpers.determine_dtype(func.type, func.return_ptr_level)
            add_c_function_to_scope f_name, f_scope, func.arg_list, return_type
          end
        end

        def analyse_auxillary_c_functions
          @auxillary_c_functions.each_value do |func|
            func.analyse_statement(@scope)
          end
        end

        # Detach the user-supplied auxlically C functions from the class and
        #   store them in Hash @auxillary_c_functions. Make modifications to
        #   them if necessary and also set an ivar that indicates if an
        #   auxillary function is user-supplied or not.
        def detach_and_modify_auxillary_c_functions_from_statements
          @auxillary_c_functions = {}

          indexes = []
          @statements.each_with_index do |stmt, idx|
            if stmt.is_a?(CFunctionDef)
              if stmt.name == ALLOC_FUNC_NAME
                @auxillary_c_functions[ALLOC_FUNC_NAME] = stmt
                @user_defined_alloc = true
                indexes << idx
              elsif stmt.name == DEALLOC_FUNC_NAME
                @auxillary_c_functions[DEALLOC_FUNC_NAME] = stmt
                @user_defined_dealloc = true
                modify_dealloc_func stmt
                indexes << idx
              elsif stmt.name == MEMCOUNT_FUNC_NAME
                @auxillary_c_functions[MEMCOUNT_FUNC_NAME] = stmt
                @user_defined_memcount = true
                indexes << idx
              elsif stmt.name == GET_STRUCT_FUNC_NAME
                @auxillary_c_functions[GET_STRUCT_FUNC_NAME] = stmt
                @user_defined_get_struct = true
                indexes << idx
              end
            end
          end

          indexes.each do |idx|
            @statements.delete_at idx
          end
        end

        def write_auxillary_c_functions(code)
          write_dealloc_c_function code
          write_memcount_c_function code
        end

        # Actually write the alloc function into C code.
        def write_alloc_c_function(code)
          if user_defined_alloc?
            @auxillary_c_functions[ALLOC_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @alloc_c_func.type.type.to_s,
              c_name: @alloc_c_func.c_name,
              args: Helpers.create_arg_arrays(@alloc_c_func.type.arg_list)
            )
            code.block do
              lines = ''
              lines << "#{@data_struct.entry.c_name} *data;\n\n"

              lines << "data = (#{@data_struct.entry.c_name}*)xmalloc("
              lines << "sizeof(#{@data_struct.entry.c_name}));\n"

              lines << member_struct_allocations

              lines << 'return TypedData_Wrap_Struct('
              lines << "#{@alloc_c_func.type.arg_list[0].entry.c_name},"
              lines << "&#{@data_type_t}, data);\n"

              code << lines
            end
          end
        end

        # TODO: modify for supporting inheritance
        def member_struct_allocations
          c_name = @scope.find(@attached_type).c_name
          "data->#{Rubex::POINTER_PREFIX + @attached_type} = (#{c_name}*)xmalloc(sizeof(#{c_name}));\n"
        end

        # Actually write the dealloc function into C code.
        def write_dealloc_c_function(code)
          if user_defined_dealloc?
            @auxillary_c_functions[DEALLOC_FUNC_NAME].generate_code code
          else
            # TODO: define dealloc if user hasnt supplied.
          end
        end

        # Actually write the memcount function into C code.
        def write_memcount_c_function(code)
          if user_defined_memcount?
            @auxillary_c_functions[MEMCOUNT_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @memcount_c_func.type.type.to_s,
              c_name: @memcount_c_func.c_name,
              args: Helpers.create_arg_arrays(@memcount_c_func.type.arg_list)
            )
            code.block do
              code << "return sizeof(#{@memcount_c_func.type.arg_list[0].entry.c_name})"
              code.colon
              code.nl
            end
          end
        end

        # Actually write the get_struct function into C code.
        def write_get_struct_c_function(code)
          if user_defined_get_struct?
            @auxillary_c_functions[GET_STRUCT_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @get_struct_c_func.type.type.to_s,
              c_name: @get_struct_c_func.c_name,
              args: Helpers.create_arg_arrays(@get_struct_c_func.type.arg_list)
            )
            code.block do
              lines = ''
              lines << "#{@data_struct.entry.c_name} *data;\n\n"
              lines << 'TypedData_Get_Struct('
              lines << "#{@get_struct_c_func.type.arg_list[0].entry.c_name}, "
              lines << "#{@data_struct.entry.c_name}, &#{@data_type_t}, data);\n"
              lines << "return data;\n"

              code << lines
            end
          end
        end

        def write_data_type_t_struct(code)
          decl = ''
          decl << "static const rb_data_type_t #{@data_type_t} = {\n"
          decl << "  \"#{@name}\",\n"
          decl << "  {0, #{@dealloc_c_func.c_name}, #{@memcount_c_func.c_name},\n"
          decl << "  0}, 0, 0, RUBY_TYPED_FREE_IMMEDIATELY\n"
          decl << "};\n"

          code << decl
          code.new_line
        end

        # Prepare the data holding struct 'data' that will hold a pointer to the
        #   struct that is attached to this class.
        def prepare_data_holding_struct
          struct_name = @name + '_data_struct'
          declarations = declarations_for_data_struct
          @data_struct = Statement::CStructOrUnionDef.new(
            :struct, struct_name, declarations, @location
          )
          @data_struct.analyse_statement(@scope)
          @statements.unshift @data_struct
        end

        # TODO: support inherited attached structs.
        def declarations_for_data_struct
          stmts = []
          stmts << Statement::CPtrDecl.new(@attached_type, @attached_type, nil,
                                           '*', @location)

          stmts
        end

        def prepare_rb_data_type_t_struct
          @data_type_t = Rubex::ATTACH_CLASS_PREFIX + '_' + @name + '_data_type_t'
        end

        # Prepare auxillary function in case they have not been supplied by user
        #   and create ivars for their Symbol Table entries for easy accesss later.
        def prepare_auxillary_c_functions
          prepare_alloc_c_function
          prepare_memcount_c_function
          prepare_deallocation_c_function
          prepare_get_struct_c_function
        end

        def ruby_method_or_c_func?(stmt)
          stmt.is_a?(RubyMethodDef) || stmt.is_a?(CFunctionDef)
        end

        # Rewrite method `stmt` so that the `data` variable becomes available
        #   inside the scope of the method.
        def rewrite_method_with_data_fetching(stmt)
          data_stmt = Statement::CPtrDecl.new(@data_struct.name, 'data',
                                              get_struct_func_call(stmt), '*', @location)
          stmt.statements.unshift data_stmt
        end

        def get_struct_func_call(_stmt)
          Expression::CommandCall.new(nil, @get_struct_c_func.name,
                                      Statement::ArgumentList.new([]))
        end

        # Create an alloc function if it is not supplied by user.
        def prepare_alloc_c_function
          if user_defined_alloc?
            @alloc_c_func = @scope.find(ALLOC_FUNC_NAME)
          else
            c_name = c_func_c_name(ALLOC_FUNC_NAME)
            scope = Rubex::SymbolTable::Scope::Local.new(ALLOC_FUNC_NAME, @scope)
            arg_list = Statement::ArgumentList.new([
                                                     Expression::ArgDeclaration.new(
                                                       dtype: 'object',
                                                       variables: [
                                                         {
                                                           ident: 'self'
                                                         }
                                                       ]
                                                     )
                                                   ])
            arg_list.analyse_statement(scope)
            @alloc_c_func = @scope.add_c_method(
              name: ALLOC_FUNC_NAME,
              c_name: c_name,
              arg_list: arg_list,
              return_type: DataType::RubyObject.new,
              scope: scope
            )
          end
        end

        # Create a memcount function if it is not supplied by user.
        def prepare_memcount_c_function
          if user_defined_memcount?
            @memcount_c_func = @scope.find(MEMCOUNT_FUNC_NAME)
          else
            c_name = c_func_c_name(MEMCOUNT_FUNC_NAME)
            scope = Rubex::SymbolTable::Scope::Local.new(MEMCOUNT_FUNC_NAME, @scope)
            arg_list = Statement::ArgumentList.new([
                                                     Expression::ArgDeclaration.new(
                                                       dtype: 'void',
                                                       variables: [
                                                         {
                                                           ptr_level: '*',
                                                           ident: 'raw_data'
                                                         }
                                                       ]
                                                     )
                                                   ])
            arg_list.analyse_statement(scope)
            @memcount_c_func = @scope.add_c_method(
              name: MEMCOUNT_FUNC_NAME,
              c_name: c_name,
              arg_list: arg_list,
              return_type: DataType::Size_t.new,
              scope: scope
            )
          end
        end

        # Create a deallocate function if it is not supplied by user.
        def prepare_deallocation_c_function
          if user_defined_dealloc?
            @dealloc_c_func = @scope.find(DEALLOC_FUNC_NAME)
          else
            c_name = c_func_c_name(DEALLOC_FUNC_NAME)
            scope = Rubex::SymbolTable::Scope::Local.new(DEALLOC_FUNC_NAME, @scope)
            arg_list = Statement::ArgumentList.new([
                                                     Expression::ArgDeclaration.new(
                                                       dtype: 'void',
                                                       variables: [
                                                         {
                                                           ptr_level: '*',
                                                           ident: 'raw_data'
                                                         }
                                                       ]
                                                     )
                                                   ])
            arg_list.analyse_statement(scope)
            @dealloc_c_func = @scope.add_c_method(
              name: DEALLOC_FUNC_NAME,
              c_name: c_name,
              return_type: DataType::Void.new,
              scope: scope,
              arg_list: arg_list
            )
          end
        end

        # Create a get_struct function if it is not supplied by user.
        def prepare_get_struct_c_function
          if user_defined_get_struct?
            @get_struct_c_func = @scope.find(GET_STRUCT_FUNC_NAME)
          else
            c_name = c_func_c_name(GET_STRUCT_FUNC_NAME)
            scope = Rubex::SymbolTable::Scope::Local.new(
              GET_STRUCT_FUNC_NAME, @scope
            )
            arg_list = Statement::ArgumentList.new([
                                                     Expression::ArgDeclaration.new(
                                                       dtype: 'object',
                                                       variables: [
                                                         {
                                                           ident: 'obj'
                                                         }
                                                       ]
                                                     )
                                                   ])
            arg_list.analyse_statement(scope)
            return_type = DataType::CPtr.new(
              DataType::CStructOrUnion.new(
                :struct, @data_struct.name, @data_struct.entry.c_name, nil
              )
            )
            @get_struct_c_func = @scope.add_c_method(
              name: GET_STRUCT_FUNC_NAME,
              c_name: c_name,
              return_type: return_type,
              arg_list: arg_list,
              scope: scope
            )
          end
        end

        # Modify the dealloc function by adding an argument of type void* so
        #   that it is compatible with what Ruby expects. This is done so that
        #   the user is not burdened with additional knowledge of knowing the
        #   the correct argument for deallocate.
        def modify_dealloc_func(func)
          func.arg_list = Statement::ArgumentList.new([
                                                        Expression::ArgDeclaration.new(
                                                          dtype: 'void',
                                                          variables: [
                                                            {
                                                              ptr_level: '*',
                                                              ident: 'raw_data'
                                                            }
                                                          ]
                                                        )
                                                      ])
          value = Expression::Name.new('raw_data')
          value.typecast = Expression::Typecast.new(@data_struct.name, '*')
          data_var = Statement::CPtrDecl.new(@data_struct.name, 'data', value,
                                             '*', @location)
          xfree = Expression::CommandCall.new(nil, 'xfree',
                                              [Expression::Name.new('data')])
          data_xfree = Statement::Expression.new xfree, @location
          func.statements.unshift data_var
          func.statements.push data_xfree
        end

        def user_defined_dealloc?
          @user_defined_dealloc
        end

        def user_defined_alloc?
          @user_defined_alloc
        end

        def user_defined_memcount?
          @user_defined_memcount
        end

        def user_defined_get_struct?
          @user_defined_get_struct
        end
      end
    end
  end
end
