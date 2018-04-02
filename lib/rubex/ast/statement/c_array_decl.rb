module Rubex
  module AST
    module Statement
      class CArrayDecl < Base
        attr_reader :type, :array_list, :name, :dimension

        def initialize(type, array_ref, array_list, location)
          super(location)
          @name = array_ref.name
          @array_list = array_list
          @dimension = array_ref.pos[0]
          @type = Rubex::TYPE_MAPPINGS[type].new
        end

        def analyse_statement(local_scope, extern: false)
          @dimension.analyse_types local_scope
          create_symbol_table_entry local_scope
          return if @array_list.nil?
          analyse_array_list local_scope
          verify_array_list_types local_scope
        end

        def generate_code(code, local_scope); end

        def rescan_declarations(local_scope); end

        private

        def analyse_array_list(local_scope)
          @array_list.each do |expr|
            expr.analyse_types(local_scope)
          end
        end

        def verify_array_list_types(_local_scope)
          @array_list.all? do |expr|
            return true if @type >= expr.type
            raise "Specified type #{@type} but list contains #{expr.type}."
          end
        end

        def create_symbol_table_entry(local_scope)
          local_scope.add_carray(name: @name, c_name: Rubex::ARRAY_PREFIX + @name,
                                 dimension: @dimension, type: @type, value: @array_list)
        end
      end
    end
  end
end
