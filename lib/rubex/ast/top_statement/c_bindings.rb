module Rubex
  module AST
    module TopStatement
      class CBindings
        attr_reader :lib, :declarations, :location

        def initialize(lib, comp_opts, declarations, location)
          @lib = lib
          @comp_opts = comp_opts
          @declarations = declarations
          @location = location
        end

        def analyse_statement(local_scope)
          unless @declarations
            @declarations = []
            load_predecided_declarations
          end
          @declarations.each do |stat|
            stat.analyse_statement local_scope, extern: true
          end
          local_scope.include_files.push @lib
          update_compiler_config
        end

        def generate_code(code); end

        private

        def update_compiler_config
          @comp_opts.each do |h|
            Rubex::Compiler::CONFIG.add_link h[:link] if h[:link]
          end
        end

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
                     arg_list([arg('object', '', 'ary'), arg('object', '', 'item')]))
        end

        def atox_functions
          [
            %w[int atoi], %w[long atol], ['long long', 'atoll'],
            %w[double atof]
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
          stmts = %w[
            T_ARRAY T_NIL T_TRUE T_FALSE T_FLOAT T_FIXNUM
            T_BIGNUM T_REGEXP T_STRING
          ].map do |ident|
            Statement::VarDecl.new('int', ident, nil, @location)
          end

          stmts
        end

        def xmalloc
          args = Statement::ArgumentList.new([
                                               Expression::ArgDeclaration.new(
                                                 dtype: 'size_t', variables: [{ ident: 'dummy' }]
                                               )
                                             ])
          Statement::CFunctionDecl.new('void', '*', 'xmalloc', args)
        end

        def xfree
          cfunc_decl 'void', '', 'xfree', arg_list([arg('void', '*', 'dummy')])
        end

        private

        def arg(type, ptr_level, ident)
          Expression::ArgDeclaration.new(
            dtype: type, variables: [{ ident: ident, ptr_level: ptr_level }]
          )
        end

        def cfunc_decl(return_type, return_ptr_level, ident, args)
          Statement::CFunctionDecl.new(return_type, return_ptr_level, ident, args)
        end

        def arg_list(args)
          Statement::ArgumentList.new args
        end
      end

    end
  end
end
