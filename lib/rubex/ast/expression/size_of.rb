module Rubex
  module AST
    module Expression
      # C sizeof operator.
      class SizeOf < Base
        def initialize(type, ptr_level)
          @size_of_type = Helpers.determine_dtype type, ptr_level
        end

        def analyse_types(local_scope)
          @type = DataType::ULInt.new
          super
        end

        def c_code(_local_scope)
          "sizeof(#{@size_of_type})"
        end
      end
    end
  end
end
