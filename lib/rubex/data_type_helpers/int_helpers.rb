module Rubex
  module DataType
    module IntHelpers
      include Helpers
      def to_ruby_object(arg)
        "INT2NUM(#{arg})"
      end
    end
  end
end
