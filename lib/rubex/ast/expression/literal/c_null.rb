module Rubex
  module AST
    module Expression
      module Literal
        class CNull < Base
          def initialize name
            # Rubex treats NULL's dtype as void*
            super
            @type = Rubex::DataType::CPtr.new(Rubex::DataType::Void.new)
          end
        end # class CNull
      end
    end
  end
end
