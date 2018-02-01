module Rubex
  module AST
    module Expression
      class ArgDeclaration < Base
        # Keep data_hash attr_reader because this node is coerced into
        # specialized ArgDecl nodes in the parser.
        attr_reader :data_hash
        def initialize(data_hash)
          @data_hash = data_hash
        end

        # TODO: Support array of function pointers and array in arguments.
        def analyse_types(local_scope, extern: false)
          var, dtype, ident, ptr_level, value = fetch_data
          name = ident
          c_name = Rubex::ARG_PREFIX + ident
          @type = Helpers.determine_dtype(dtype, ptr_level)
          value&.analyse_types(local_scope)
          add_arg_to_symbol_table name, c_name, value, extern, local_scope
          @has_temp = true if @type.object?
        end

        private

        def add_arg_to_symbol_table(name, c_name, value, extern, local_scope)
          unless extern
            @entry = local_scope.add_arg(name: name, c_name: c_name, type: @type, value: value)
          end
        end

        def fetch_data
          var       = @data_hash[:variables][0]
          dtype     = @data_hash[:dtype]
          ident     = var[:ident]
          ptr_level = var[:ptr_level]
          value     = var[:value]

          [var, dtype, ident, ptr_level, value]
        end
      end
    end
  end
end
