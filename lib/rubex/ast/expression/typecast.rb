module Rubex
  module AST
    module Expression
      class Typecast < Base
        def initialize dtype, ptr_level
          @dtype, @ptr_level = dtype, ptr_level
        end

        def analyse_types local_scope
          @type = Rubex::Helpers.determine_dtype @dtype, @ptr_level
        end

        def c_code local_scope
          "(#{@type.to_s})"
        end
      end
    end
  end
end
