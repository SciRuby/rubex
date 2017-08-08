module Rubex
  module AST
    module TopStatement
      class CBindings
        attr_reader :lib, :declarations, :location

        def initialize lib, declarations, location
          @lib, @declarations, @location = lib, declarations, location
        end

        def analyse_statement local_scope
          unless @declarations
            @declarations = []
            load_predecided_declarations
          end

          @declarations.each do |stat|
            stat.analyse_statement local_scope, extern: true
          end
          local_scope.include_files.push @lib
        end

        def generate_code code

        end

      private

        def load_predecided_declarations
          if @lib == 'rubex/ruby'
            load_ruby_functions_and_types
            @lib = '<ruby.h>'
          elsif @lib == 'rubex/ruby/encoding'
            load_ruby_encoding_functions_and_type
            @lib = '<ruby/encoding.h>'
          elsif @lib == 'rubex/stdlib'
            load_stdlib_functions_and_types
            @lib = '<stdlib.h>'
          else
            raise Rubex::LibraryNotFoundError, "Cannot find #{@lib}."
          end
        end

        def load_ruby_functions_and_types
          @declarations << xmalloc
          @declarations << xfree
          @declarations << type_get
          @declarations.concat type_identifiers
          @declarations << rb_str_new
          @declarations << rb_ary_includes
        end

        def load_ruby_encoding_functions_and_type
          @declarations << rb_enc_associate_index
          @declarations << rb_enc_find_index
        end

        def load_stdlib_functions_and_types
          @declarations.concat atox_functions
        end

        def rb_ary_includes
          cfunc_decl('object', '', 'rb_ary_includes', 
            arg_list([arg('object', '','ary'), arg('object', '','item')]))
        end

        def atox_functions
          [
            ['int', 'atoi'], ['long', 'atol'], ['long long', 'atoll'],
            ['double', 'atof']
          ].map do |type, ident|
            cfunc_decl(type, '', ident, arg_list([arg('char', '*', 'str')]))
          end
        end

        def rb_enc_find_index
          cfunc_decl('int', '', 'rb_enc_find_index', 
            arg_list([arg('char', '*', 'enc')]))
        end

        def rb_enc_associate_index
          args = arg_list([arg('object', '', 'string'), arg('int', '', 'enc')])
          cfunc_decl('object', '', 'rb_enc_associate_index', args)
        end

        def rb_str_new
          args = arg_list([arg('char', '*', 'str'), arg('long', '', 'length')])
          cfunc_decl('object', '', 'rb_str_new', args)
        end

        def type_get
          cfunc_decl('int', '', 'TYPE', arg_list([arg('object', '', 'dummy')]))
        end

        def type_identifiers
          stmts = [
            'T_ARRAY', 'T_NIL', 'T_TRUE', 'T_FALSE', 'T_FLOAT', 'T_FIXNUM',
            'T_BIGNUM', 'T_REGEXP', 'T_STRING'
          ].map do |ident|
            Statement::VarDecl.new('int', ident, nil, @location)
          end

          stmts
        end

        def xmalloc
          args = Statement::ArgumentList.new([
            Expression::ArgDeclaration.new({ 
              dtype: 'size_t', variables: [{ident: 'dummy'}] })
          ])
          Statement::CFunctionDecl.new('void', '*', 'xmalloc', args)  
        end

        def xfree
          cfunc_decl 'void', '', 'xfree', arg_list([arg('void', '*', 'dummy')])
        end

      private

        def arg type, ptr_level, ident
          Expression::ArgDeclaration.new({
            dtype: type, variables: [{ ident: ident, ptr_level: ptr_level }]
            })
        end

        def cfunc_decl return_type, return_ptr_level, ident, args
          Statement::CFunctionDecl.new(return_type, return_ptr_level, ident, args)
        end

        def arg_list args
          Statement::ArgumentList.new args
        end
      end # class CBindings

      class MethodDef
        include Rubex::Helpers::Writers
        # Ruby name of the method.
        attr_reader :name
        # Method arguments. Accessor because arguments need to be modified in
        # case of auxillary C functions of attach classes.
        attr_accessor :arg_list
        # The statments/expressions contained within the method.
        attr_reader :statements
        # Symbol Table entry.
        attr_reader :entry
        # Instance of Scope::Local for this method.
        attr_reader :scope
        # Variable name that identifies 'self'
        attr_reader :self_name

        def initialize name, arg_list, statements
          @name, @arg_list, @statements = name, arg_list, statements
          @self_name = Rubex::ARG_PREFIX + "self"
        end

        def analyse_statement outer_scope
          # @scope = Rubex::SymbolTable::Scope::Local.new @name, outer_scope
          @entry = outer_scope.find @name
          @scope = @entry.type.scope
          @scope.type = @entry.type
          @scope.self_name = @self_name
          @arg_list = @entry.type.arg_list
          # @arg_list.analyse_statement(@scope) if @arg_list
          # @entry.type.arg_list = @arg_list
          @statements.each do |stat|
            stat.analyse_statement @scope
          end
        end

        # Option c_function - When set to true, certain code that is not required
        #   for Ruby methods will be generated too.
        def generate_code code, c_function: false
          code.block do
            generate_function_definition code, c_function: c_function
          end
        end

        def rescan_declarations scope
          @statements.each do |stat|
            stat.respond_to?(:rescan_declarations) and
            stat.rescan_declarations(@scope)
          end
        end

      private
        def generate_function_definition code, c_function:
          declare_types code, @scope
          declare_args code unless c_function
          declare_vars code, @scope
          declare_carrays code, @scope
          declare_ruby_objects code, @scope
          declare_temps code, @scope
          generate_arg_checking code unless c_function
          init_args code unless c_function
          declare_carrays_using_init_var_value code
          generate_statements code
        end

        def declare_args code
          @scope.arg_entries.each do |arg|
            code.declare_variable type: arg.type.to_s, c_name: arg.c_name
          end
        end

        def generate_statements code
          @statements.each do |stat|
            stat.generate_code code, @scope
          end
        end

        def init_args code
          @scope.arg_entries.each_with_index do |arg, i|
            code << arg.c_name + '=' + arg.type.from_ruby_object("argv[#{i}]") + ';'
            code.nl
          end
        end

        def declare_carrays_using_init_var_value code
          @scope.carray_entries.select { |s|
            !s.type.dimension.is_a?(Rubex::AST::Expression::Literal::Base)
          }. each do |arr|
            type = arr.type.type.to_s
            c_name = arr.c_name
            dimension = arr.type.dimension.c_code(@scope)
            value = arr.value.map { |a| a.c_code(@scope) } if arr.value
            code.declare_carray(type: type, c_name: c_name, dimension: dimension,
              value: value)
          end
        end

        def generate_arg_checking code
          code << 'if (argc < ' + @scope.arg_entries.size.to_s + ")"
          code.block do
            code << %Q{rb_raise(rb_eArgError, "Need #{@scope.arg_entries.size} args, not %d", argc);\n}
          end
        end
      end

      class RubyMethodDef < MethodDef
        attr_reader :singleton

        def initialize name, arg_list, statements, singleton: false
          super(name, arg_list, statements)
          @singleton = singleton
        end

        def analyse_statement local_scope
          super
          @entry.singleton = @singleton
        end

        def generate_code code
          code.write_ruby_method_header(type: @entry.type.type.to_s,
            c_name: @entry.c_name)
          super
        end

        def == other
          self.class == other.class && @name == other.name &&
          @c_name == other.c_name && @arg_list == other.arg_list &&
          @statements == other.statements && @entry == other.entry &&
          @type == other.type
        end
      end # class RubyMethodDef

      class CFunctionDef < MethodDef
        attr_reader :type, :return_ptr_level

        def initialize type, return_ptr_level, name, arg_list, statements
          super(name, arg_list, statements)
          @type = type
          @return_ptr_level = return_ptr_level
        end

        def analyse_statement outer_scope, extern: false
          super(outer_scope)
        end

        def generate_code code
          code.write_c_method_header(type: @entry.type.type.to_s, 
            c_name: @entry.c_name, args: Helpers.create_arg_arrays(@arg_list))
          super code, c_function: true
        end
      end # class CFunctionDef

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
        def initialize name, ancestor, statements
          @name, @ancestor, @statements = name, ancestor, statements
          @ancestor = 'Object' if @ancestor.nil?
        end

        def analyse_statement local_scope, attach_klass: false
          @entry = local_scope.find(@name)
          @scope = @entry.type.scope
          @ancestor = @entry.type.ancestor
          add_statement_symbols_to_symbol_table
          if !attach_klass
            @statements.each do |stat|
              stat.analyse_statement @scope
            end
          end
        end

        def rescan_declarations local_scope
          @statements.each do |stat|
            stat&.rescan_declarations(@scope)
          end
        end

        def generate_code code
          @statements.each do |stat|
            stat.generate_code code
          end
        end

      protected

        def add_statement_symbols_to_symbol_table
          @statements.each do |stmt|
            if ruby_method_or_c_function?(stmt)
              f_name, f_scope = prepare_name_and_scope_of_functions(stmt)
              if !auxillary_c_function_for_attached_klass?(f_name)
                stmt.arg_list.analyse_statement(f_scope)
                if stmt.is_a? Rubex::AST::TopStatement::RubyMethodDef
                  add_ruby_method_to_scope f_name, f_scope, stmt.arg_list
                elsif stmt.is_a? Rubex::AST::TopStatement::CFunctionDef
                  return_type = Helpers.determine_dtype(stmt.type, stmt.return_ptr_level)
                  add_c_function_to_scope f_name, f_scope, stmt.arg_list, return_type
                end
              end
            end
          end
        end

        def auxillary_c_function_for_attached_klass? f_name
          self.is_a?(AttachedKlass) and [
            Rubex::ALLOC_FUNC_NAME, Rubex::DEALLOC_FUNC_NAME, 
            Rubex::MEMCOUNT_FUNC_NAME, Rubex::GET_STRUCT_FUNC_NAME
          ].include?(f_name)
        end

        def add_c_function_to_scope f_name, f_scope, arg_list, return_type
          c_name = c_func_c_name(f_name)
          arg_list.each do |arg|
            if arg.entry.value
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

        def add_ruby_method_to_scope f_name, f_scope, arg_list
          c_name = Rubex::RUBY_FUNC_PREFIX + @name + "_" +
            f_name.gsub("?", "_qmark").gsub("!", "_bang")
          @scope.add_ruby_method(
            name: f_name,
            c_name: c_name, 
            scope: f_scope,
            arg_list: arg_list
          )
        end

        def prepare_name_and_scope_of_functions stmt
          f_name = stmt.name
          f_scope = Rubex::SymbolTable::Scope::Local.new f_name, @scope
          [f_name, f_scope]
        end

        def ruby_method_or_c_function? stmt
          stmt.is_a?(Rubex::AST::TopStatement::RubyMethodDef) ||
          stmt.is_a?(Rubex::AST::TopStatement::CFunctionDef)
        end

        def c_func_c_name name
          Rubex::C_FUNC_PREFIX + @name + "_" + name
        end
      end # class Klass

      class AttachedKlass < Klass

        attr_reader :attached_type

        ALLOC_FUNC_NAME      = Rubex::ALLOC_FUNC_NAME          
        DEALLOC_FUNC_NAME    = Rubex::DEALLOC_FUNC_NAME        
        MEMCOUNT_FUNC_NAME   = Rubex::MEMCOUNT_FUNC_NAME      
        GET_STRUCT_FUNC_NAME = Rubex::GET_STRUCT_FUNC_NAME  

        def initialize name, attached_type, ancestor, statements, location
          @attached_type = attached_type
          @location = location
          super(name, ancestor, statements)
        end

        def analyse_statement outer_scope
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

        def generate_code code
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

        def write_auxillary_c_functions code
          write_dealloc_c_function code
          write_memcount_c_function code
        end

        # Actually write the alloc function into C code.
        def write_alloc_c_function code
          if user_defined_alloc?
            @auxillary_c_functions[ALLOC_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @alloc_c_func.type.type.to_s, 
              c_name: @alloc_c_func.c_name, 
              args: Helpers.create_arg_arrays(@alloc_c_func.type.arg_list))
            code.block do
              lines = ""
              lines << "#{@data_struct.entry.c_name} *data;\n\n"

              lines << "data = (#{@data_struct.entry.c_name}*)xmalloc("
              lines << "sizeof(#{@data_struct.entry.c_name}));\n"

              lines << member_struct_allocations

              lines << "return TypedData_Wrap_Struct("
              lines << "#{@alloc_c_func.type.arg_list[0].entry.c_name},"
              lines << "&#{@data_type_t}, data);\n"

              code << lines
            end
          end
        end

        #TODO: modify for supporting inheritance
        def member_struct_allocations
          c_name = @scope.find(@attached_type).c_name
          "data->#{Rubex::POINTER_PREFIX + @attached_type} = (#{c_name}*)xmalloc(sizeof(#{c_name}));\n"
        end

        # Actually write the dealloc function into C code.
        def write_dealloc_c_function code
          if user_defined_dealloc?
            @auxillary_c_functions[DEALLOC_FUNC_NAME].generate_code code
          else
            # TODO: define dealloc if user hasnt supplied.
          end
        end

        # Actually write the memcount function into C code.
        def write_memcount_c_function code
          if user_defined_memcount?
            @auxillary_c_functions[MEMCOUNT_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @memcount_c_func.type.type.to_s, 
              c_name: @memcount_c_func.c_name, 
              args: Helpers.create_arg_arrays(@memcount_c_func.type.arg_list))
            code.block do
              code << "return sizeof(#{@memcount_c_func.type.arg_list[0].entry.c_name})"
              code.colon
              code.nl
            end
          end
        end

        # Actually write the get_struct function into C code.
        def write_get_struct_c_function code
          if user_defined_get_struct?
            @auxillary_c_functions[GET_STRUCT_FUNC_NAME].generate_code code
          else
            code.write_c_method_header(
              type: @get_struct_c_func.type.type.to_s, 
              c_name: @get_struct_c_func.c_name, 
              args: Helpers.create_arg_arrays(@get_struct_c_func.type.arg_list))
            code.block do
              lines = ""
              lines << "#{@data_struct.entry.c_name} *data;\n\n"
              lines << "TypedData_Get_Struct("
              lines << "#{@get_struct_c_func.type.arg_list[0].entry.c_name}, "
              lines << "#{@data_struct.entry.c_name}, &#{@data_type_t}, data);\n"
              lines << "return data;\n"

              code << lines
            end
          end
        end

        def write_data_type_t_struct code
          decl = ""
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
          struct_name = @name + "_data_struct"
          declarations = declarations_for_data_struct
          @data_struct = Statement::CStructOrUnionDef.new(
            :struct, struct_name, declarations, @location)
          @data_struct.analyse_statement(@scope)
          @statements.unshift @data_struct
        end

        # TODO: support inherited attached structs.
        def declarations_for_data_struct
          stmts = []
          stmts << Statement::CPtrDecl.new(@attached_type, @attached_type, nil, 
            "*", @location)

          stmts
        end

        def prepare_rb_data_type_t_struct
          @data_type_t = Rubex::ATTACH_CLASS_PREFIX + "_" + @name + "_data_type_t"
        end

        # Prepare auxillary function in case they have not been supplied by user
        #   and create ivars for their Symbol Table entries for easy accesss later.
        def prepare_auxillary_c_functions
          prepare_alloc_c_function
          prepare_memcount_c_function
          prepare_deallocation_c_function
          prepare_get_struct_c_function
        end

        def ruby_method_or_c_func? stmt
          stmt.is_a?(RubyMethodDef) || stmt.is_a?(CFunctionDef)
        end

        # Rewrite method `stmt` so that the `data` variable becomes available
        #   inside the scope of the method.
        def rewrite_method_with_data_fetching stmt
          data_stmt = Statement::CPtrDecl.new(@data_struct.name, 'data', 
            get_struct_func_call(stmt), "*", @location)
          stmt.statements.unshift data_stmt
        end

        def get_struct_func_call stmt
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
              Expression::ArgDeclaration.new({
                dtype: 'object',
                variables: [
                  {
                    ident: 'self'
                  }
                ]
              })
            ])
            arg_list.analyse_statement(scope)
            @alloc_c_func = @scope.add_c_method(
              name: ALLOC_FUNC_NAME,
              c_name: c_name, 
              arg_list: arg_list,
              return_type: DataType::RubyObject.new,
              scope: scope)
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
              Expression::ArgDeclaration.new({ 
                dtype: "void", 
                variables: [
                    {
                      ptr_level: "*",
                      ident: "raw_data"
                    }
                  ]
                })
              ])
            arg_list.analyse_statement(scope)
            @memcount_c_func = @scope.add_c_method(
              name: MEMCOUNT_FUNC_NAME,
              c_name: c_name,
              arg_list: arg_list,
              return_type: DataType::Size_t.new,
              scope: scope)
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
              Expression::ArgDeclaration.new({
                dtype: "void",
                variables: [
                    {
                      ptr_level: "*",
                      ident: "raw_data"
                    }
                  ]
                })
              ])
            arg_list.analyse_statement(scope)
            @dealloc_c_func = @scope.add_c_method(
              name: DEALLOC_FUNC_NAME,
              c_name: c_name, 
              return_type: DataType::Void.new,
              scope: scope,
              arg_list: arg_list)
          end
        end

        # Create a get_struct function if it is not supplied by user.
        def prepare_get_struct_c_function
          if user_defined_get_struct?
            @get_struct_c_func = @scope.find(GET_STRUCT_FUNC_NAME)
          else
            c_name = c_func_c_name(GET_STRUCT_FUNC_NAME)
            scope = Rubex::SymbolTable::Scope::Local.new(
              GET_STRUCT_FUNC_NAME, @scope)
            arg_list = Statement::ArgumentList.new([
              Expression::ArgDeclaration.new({
                  dtype: "object",
                  variables: [
                    {
                      ident: "obj"
                    }
                  ]
                })
              ])
            arg_list.analyse_statement(scope)
            return_type = DataType::CPtr.new(
                            DataType::CStructOrUnion.new(
                    :struct, @data_struct.name, @data_struct.entry.c_name, nil)
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
        def modify_dealloc_func func
          func.arg_list = Statement::ArgumentList.new([
              Expression::ArgDeclaration.new({
                dtype: "void",
                variables: [
                    {
                      ptr_level: "*",
                      ident: "raw_data"
                    }
                  ]
                })
              ])
          value = Expression::Name.new('raw_data')
          value.typecast = Expression::Typecast.new(@data_struct.name, "*")
          data_var = Statement::CPtrDecl.new(@data_struct.name, 'data', value, 
            "*", @location)
          func.statements.unshift data_var
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
      end # class AttachedKlass
    end # module TopStatement
  end # module AST
end # module Rubex