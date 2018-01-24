module Rubex
  module AST
    module Expression
      module Literal
        class False < Base
          def initialize(name)
            super
          end

          def analyse_for_target_type(target_type, _local_scope)
            @type = if target_type.object?
                      Rubex::DataType::FalseType.new
                    else
                      Rubex::DataType::CBoolean.new
                    end
          end

          def analyse_types(_local_scope)
            @type = Rubex::DataType::FalseType.new
          end

          def c_code(_local_scope)
            if @type.object?
              @name
            else
              '0'
            end
          end
        end # class False
      end
    end
  end
end
