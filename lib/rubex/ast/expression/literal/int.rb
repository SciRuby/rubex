module Rubex
  module AST
    module Expression
      module Literal
        class Int < Base
          def initialize name
            super
            @type = Rubex::DataType::Int.new
          end
        end
      end
    end
  end
end
