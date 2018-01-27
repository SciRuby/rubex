module Rubex
  module DataType
    class LLInt
      include IntHelpers
      def to_s
        'long long int'
      end

      def to_ruby_object(arg)
        "LL2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "NUM2LL(#{arg})"
      end

      def llint?
        true
      end

      def p_formatter
        '%ll'
      end
    end
  end
end
