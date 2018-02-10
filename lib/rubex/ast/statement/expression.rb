module Rubex
  module AST
    module Statement
      class Expression < Base
        def initialize(expr, location)
          super(location)
          @expr = expr
        end

        def analyse_statement(local_scope)
          @expr.analyse_types local_scope
          @expr.allocate_temps local_scope
          @expr.release_temps local_scope
        end

        def generate_code(code, local_scope)
          super
          @expr.generate_evaluation_code code, local_scope
          code << @expr.c_code(local_scope) + ';'
          code.nl
          @expr.generate_disposal_code code
        end
      end
    end
  end
end
