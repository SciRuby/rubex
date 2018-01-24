module Rubex
  module AST
    module Statement
      class VarDecl < Base
        attr_reader :type, :value

        def initialize(type, name, value, location)
          super(location)
          @name = name
          @value = value
          @type = type
        end

        def analyse_statement(local_scope, extern: false)
          # TODO: Have type checks for knowing if correct literal assignment
          # is taking place. For example, a char should not be assigned a float.
          @type = Helpers.determine_dtype @type, ''
          c_name = extern ? @name : Rubex::VAR_PREFIX + @name
          if @value
            @value.analyse_for_target_type(@type, local_scope)
            @value.allocate_temp local_scope, @value.type
            @value = Helpers.to_lhs_type(self, @value)
            @value.release_temp local_scope
          end

          local_scope.declare_var name: @name, c_name: c_name, type: @type,
                                  value: @value, extern: extern
        end

        def rescan_declarations(scope)
          if @type.is_a? String
            @type = Rubex::CUSTOM_TYPES[@type]
            scope[@name].type = @type
          end
        end

        def generate_code(code, local_scope)
          if @value
            @value.generate_evaluation_code code, local_scope
            lhs = local_scope.find(@name).c_name
            code << "#{lhs} = #{@value.c_code(local_scope)};"
            code.nl
            @value.generate_disposal_code code
          end
        end
      end
    end
  end
end
