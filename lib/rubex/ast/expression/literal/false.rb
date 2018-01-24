module Rubex
  module AST
    module Expression
      module Literal
        class False < Base
          def initialize name
            super
          end

          def analyse_for_target_type target_type, local_scope
            if target_type.object?
              @type = Rubex::DataType::FalseType.new
            else
              @type = Rubex::DataType::CBoolean.new
            end
          end

          def analyse_types local_scope
            @type = Rubex::DataType::FalseType.new
          end

          def c_code local_scope
            if @type.object?
              @name
            else
              "0"
            end
          end
        end # class False
      end
    end
  end
end
