module Rubex
  module AST
    module Expression
      module Literal
        class True < Base

          def analyse_for_target_type target_type, local_scope
            if target_type.object?
              @type = Rubex::DataType::TrueType.new
            else
              @type = Rubex::DataType::CBoolean.new
            end
          end

          def analyse_types local_scope
            @type = Rubex::DataType::TrueType.new
          end

          def c_code local_scope
            if @type.object?
              @name
            else
              "1"
            end
          end
        end # class True
      end
    end
  end
end
