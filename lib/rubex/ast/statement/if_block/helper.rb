module Rubex
  module AST
    module Statement
      class IfBlock < Base
        module Helper
          def analyse_statement(local_scope)
            @statements.each do |stat|
              stat.analyse_statement local_scope
            end

            @if_tail&.analyse_statement(local_scope)
          end

          def generate_code_for_statement(stat, code, local_scope, node)
            if stat != 'else'
              condition = node.expr.c_code(local_scope)
              expr_condition = node.expr.type.object? ? "RTEST(#{condition})" : condition
              code << "#{stat} (#{expr_condition}) "
            else
              code << stat.to_s
            end

            code.block do
              node.statements.each do |stat|
                stat.generate_code code, local_scope
                code.nl
              end
            end

            if stat != 'else'
              node.if_tail&.generate_code(code, local_scope)
            end
          end
        end
      end
    end
  end
end
