module Rubex
  module AST
    module Statement
      module BeginBlock
        class Else < Base
          def analyse_statement(local_scope)
            @statements.each do |stmt|
              stmt.analyse_statement local_scope
            end
          end

          def generate_code(code, local_scope)
            @statements.each do |stmt|
              stmt.generate_code code, local_scope
            end
          end
        end
      end
    end
  end
end
