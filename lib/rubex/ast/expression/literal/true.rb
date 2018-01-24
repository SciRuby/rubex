module Rubex
  module AST
    module Expression
      module Literal
        class True < Base
          def analyse_for_target_type(target_type, _local_scope)
            @type = if target_type.object?
                      Rubex::DataType::TrueType.new
                    else
                      Rubex::DataType::CBoolean.new
                    end
          end

          def analyse_types(_local_scope)
            @type = Rubex::DataType::TrueType.new
          end

          def c_code(_local_scope)
            if @type.object?
              @name
            else
              '1'
            end
          end
        end # class True
      end
    end
  end
end
