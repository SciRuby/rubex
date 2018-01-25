module Rubex
  module AST
    module Statement
      module BeginBlock
        class Base < Statement::Base
          def initialize(statements, location)
            @statements = statements
            super(location)
          end
        end
      end
    end
  end
end
