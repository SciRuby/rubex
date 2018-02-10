require_relative 'helper'
module Rubex
  module AST
    module Statement
      class IfBlock < Base
        class Else < Base
          attr_reader :statements
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize(statements, location)
            super(location)
            @statements = statements
          end

          def analyse_statement(local_scope)
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end
          end

          def generate_code(code, local_scope); end

          def if_tail
            nil
          end
        end
      end
    end
  end
end
