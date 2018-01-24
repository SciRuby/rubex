module Rubex
  module AST
    module Expression

      # Internal node that denotes empty expression for a statement for example
      #   the `return` for a C function with return type `void`.

      class Empty < Base
        attr_reader :type

        def analyse_types local_scope
          @type = DataType::Void.new
        end
      end

    end
  end
end
