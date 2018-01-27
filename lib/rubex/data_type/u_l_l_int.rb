module Rubex
  module DataType
    class ULLInt
      include UIntHelpers
      def to_s
        'unsigned long long int'
      end

      def to_ruby_object(arg)
        "ULL2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "NUM2ULL(#{arg})"
      end

      def ullint?
        true
      end

      def p_formatter
        '%llu'
      end
    end
  end
end
