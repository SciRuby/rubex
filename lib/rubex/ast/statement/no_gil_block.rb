module Rubex
  module AST
    module Statement
      class NoGilBlock < Base
        def initialize statements
          @statements = statements
        end

        def analyse_statement(local_scope)
          # steps to perform for proper release of GIL:
          # * release the GIL
          # * have code for checking of interuppts.
        end

        def generate_code(code, local_scope)
          # expected code looks something like this:
          # 
        end
      end
    end
  end
end
