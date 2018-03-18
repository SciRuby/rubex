module Rubex
  module AST
    module Expression
      class Print < Base
        def initialize(expressions)
          @expressions = expressions
        end

        def analyse_types(local_scope)
          @expressions.each do |expr|
            expr.analyse_types local_scope
            expr.allocate_temps local_scope
            expr.release_temps local_scope
          end
        end

        def generate_evaluation_code(code, local_scope)
          super
          @expressions.each do |expr|
            expr.generate_evaluation_code code, local_scope

            str = 'printf('
            str << "\"#{expr.type.p_formatter}\""
            str << ", #{inspected_expr(expr, local_scope)}"
            str << ');'
            code << str
            code.nl

            expr.generate_disposal_code code
          end

          code.nl
        end

        private

        def inspected_expr(expr, local_scope)
          obj = expr.c_code(local_scope)
          if expr.type.object?
            "RSTRING_PTR(rb_funcall(#{obj}, rb_intern(\"inspect\"), 0, NULL))"
          else
            obj
          end
        end
      end
    end
  end
end
