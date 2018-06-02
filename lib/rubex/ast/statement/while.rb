module Rubex
  module AST
    module Statement
      class While < Base
        def initialize(expr, statements, location)
          super(location)
          @expr = expr
          @statements = statements
        end

        def analyse_statement(local_scope)
          @expr.analyse_types local_scope
          @expr.allocate_temps local_scope
          @statements.each do |stat|
            stat.analyse_statement local_scope
          end
          @expr.release_temps local_scope
        end

        def generate_code(code, local_scope)
          @expr.generate_evaluation_code code, local_scope
          stmt = "while (#{@expr.c_code(local_scope)})"
          code << stmt
          code.block do
            @statements.each do |stat|
              stat.generate_code code, local_scope
            end
          end
          @expr.generate_disposal_code code
        end
      end
    end
  end
end
