module Rubex
  module AST
    module Expression
      class BlockGiven < Base
        def analyse_types(_local_scope)
          @type = DataType::CBoolean.new
        end

        def c_code(_local_scope)
          'rb_block_given_p()'
        end
      end
    end
  end
end
