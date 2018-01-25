module Rubex
  module AST
    module Expression
      class UnaryBase < Base
        def initialize(expr)
          @expr = expr
        end

        def analyse_types(local_scope)
          @expr.analyse_types local_scope
          @type = @expr.type
          @expr.allocate_temps local_scope
          @expr.allocate_temp local_scope, @type
          @expr.release_temps local_scope
          @expr.release_temp local_scope
          @expr = @expr.to_ruby_object if @type.object?
        end

        def generate_evaluation_code(code, local_scope)
          @expr.generate_evaluation_code code, local_scope
        end
      end
    end
  end
end
