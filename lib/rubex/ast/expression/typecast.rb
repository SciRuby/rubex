module Rubex
  module AST
    module Expression
      class Typecast < Base
        def initialize(dtype, ptr_level)
          @dtype = dtype
          @ptr_level = ptr_level
        end

        def analyse_types(_local_scope)
          @type = Rubex::Helpers.determine_dtype @dtype, @ptr_level
        end

        def c_code(_local_scope)
          "(#{@type})"
        end
      end
    end
  end
end
