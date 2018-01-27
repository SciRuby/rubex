module Rubex
  module AST
    module Statement
      # FIXME: this probably is an expression?
      class ActualArgList < ArgumentList
        def analyse_statement(local_scope)
          @args.each do |arg|
            arg.analyse_types local_scope
          end
        end

        def allocate_temps(local_scope)
          @args.each { |a| a.allocate_temps(local_scope) }
        end

        def release_temps(local_scope)
          @args.each { |a| a.release_temps(local_scope) }
        end

        def generate_evaluation_code(code, local_scope)
          @args.each do |a|
            a.generate_evaluation_code code, local_scope
          end
        end

        def generate_disposal_code(code)
          @args.each do |a|
            a.generate_disposal_code code
          end
        end
      end
    end
  end
end
