module Rubex
  module AST
    module Expression

      class SizeOf < Base
        attr_reader :type

        def initialize type, ptr_level
          @size_of_type = Helpers.determine_dtype type, ptr_level
        end

        def analyse_types local_scope
          @type = DataType::ULInt.new
          super
        end

        def c_code local_scope
          "sizeof(#{@size_of_type})"
        end
      end # class SizeOf
    end
  end
end
