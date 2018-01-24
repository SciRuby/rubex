module Rubex
  module AST
    module Expression
      module Literal
        class Base < Rubex::AST::Expression::Base
          def initialize(name)
            @name = name
          end

          def c_code(local_scope)
            code = super
            code << @name
          end

          def c_name
            @name
          end

          def literal?
            true
          end

          def ==(other)
            self.class == other.class && @name == other.name
          end
        end # class Base
      end
    end
  end
end
