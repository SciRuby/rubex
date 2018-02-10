module Rubex
  module AST
    module Statement
      class Assign < Base
        def initialize(lhs, rhs, location)
          super(location)
          @lhs = lhs
          @rhs = rhs
        end

        def analyse_statement(local_scope)
          if @lhs.is_a?(Rubex::AST::Expression::Name)
            @lhs.analyse_declaration @rhs, local_scope
          else
            @lhs.analyse_types(local_scope)
          end
          @lhs.allocate_temps local_scope
          @rhs.analyse_for_target_type(@lhs.type, local_scope)
          @rhs = Helpers.to_lhs_type(@lhs, @rhs)
          @rhs.allocate_temps local_scope

          @lhs.release_temps local_scope
          @rhs.release_temps local_scope
        end

        def generate_code(code, local_scope)
          super
          @rhs.generate_evaluation_code code, local_scope
          @lhs.generate_assignment_code @rhs, code, local_scope
          @rhs.generate_disposal_code code
        end
      end
    end
  end
end
