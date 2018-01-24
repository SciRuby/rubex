module Rubex
  module AST
    module Expression

      class BlockGiven < Base
        attr_reader :type

        def analyse_types local_scope
          @type = DataType::CBoolean.new
        end

        def c_code local_scope
          "rb_block_given_p()"
        end
      end
    end
  end
end
