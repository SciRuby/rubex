module Rubex
  module AST
    module Expression
      module Literal
        class Double < Base
          def initialize(name)
            super
            @type = Rubex::DataType::F64.new
          end
        end
      end
    end
  end
end
