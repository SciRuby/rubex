module Rubex
  module DataType
    class Int64
      include IntHelpers
      def to_s
        'int64_t'
      end

      def to_ruby_object(arg)
        "LONG2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "(int64_t)NUM2LONG(#{arg})"
      end

      def p_formatter
        '%ld'
      end

      def int64?
        true
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.int32? || other.int?
          1
        elsif other.int64?
          0
        else
          -1
        end
      end
    end
  end
end
