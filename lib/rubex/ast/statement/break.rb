module Rubex
  module AST
    module Statement
      class Break < Base
        def analyse_statement(local_scope)
          # TODO: figure whether this is a Ruby break or C break. For now
          #   assuming C break.
        end

        def generate_code(code, _local_scope)
          code.write_location @location
          code << 'break;'
          code.nl
        end
      end
    end
  end
end
