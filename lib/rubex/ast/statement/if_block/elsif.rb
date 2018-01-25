require_relative 'helper'
module Rubex
  module AST
    module Statement
      class IfBlock < Base
        class Elsif < Base
          attr_reader :expr, :statements, :if_tail
          include Rubex::AST::Statement::IfBlock::Helper

          def initialize(expr, statements, if_tail, location)
            super(location)
            @expr = expr
            @statements = statements
            @if_tail = if_tail
          end

          def generate_code(code, local_scope); end
        end
      end
    end
  end
end
