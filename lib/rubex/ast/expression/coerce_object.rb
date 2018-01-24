module Rubex
  module AST
    module Expression

      class CoerceObject < Base
        attr_reader :expr

        extend Forwardable

        def_delegators :@expr, :generate_evaluation_code, :generate_disposal_code,
        :generate_assignment_code, :allocate_temp, :allocate_temps,
        :release_temp, :release_temps, :type
      end
    end
  end
end
