module Rubex
  module AST
    module Expression
      module Literal
        class Nil < Base
          def initialize(name)
            super
            @type = Rubex::DataType::NilType.new
          end
        end # class Nil
      end
    end
  end
end
