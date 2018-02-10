module Rubex
  module AST
    module Statement
      class CPtrDecl < Base
        attr_reader :entry, :type

        def initialize(type, name, value, ptr_level, location)
          super(location)
          @name = name
          @type = type
          @value = value
          @ptr_level = ptr_level
        end

        def analyse_statement(local_scope, extern: false)
          cptr_cname extern
          @type = Helpers.determine_dtype @type, @ptr_level
          if @value
            @value.analyse_for_target_type(@type, local_scope)
            @value = Helpers.to_lhs_type(self, @value)
          end

          @entry = local_scope.declare_var name: @name, c_name: @c_name,
                                           type: @type, value: @value, extern: extern
        end

        def rescan_declarations(local_scope)
          base_type = @entry.type.base_type
          if base_type.is_a? String
            type = Helpers.determine_dtype base_type, @ptr_level
            local_scope[@name].type = type
          end
        end

        def generate_code(code, local_scope)
          if @value
            @value.generate_evaluation_code code, local_scope
            code << "#{local_scope.find(@name).c_name} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end

        private

        def cptr_cname(extern)
          @c_name = extern ? @name : Rubex::POINTER_PREFIX + @name
        end
      end
    end
  end
end
