module Rubex
  module DataType
    module UIntHelpers
      include Helpers
      def to_ruby_object(arg)
        "UINT2NUM(#{arg})"
      end
    end

  end
end
