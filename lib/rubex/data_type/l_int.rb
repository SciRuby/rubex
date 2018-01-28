module Rubex
  module DataType
    class LInt
      include IntHelpers
      def to_s
        'long int'
      end

      def to_ruby_object(arg)
        "LONG2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "NUM2LONG(#{arg})"
      end

      def lint?
        true
      end

      def p_formatter
        '%ld'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.int32? ||
           other .int64? || other.uint8? || other.uint16? || other.uint32? ||
           other.int?
          1
        elsif other.lint?
          0
        else
          -1
        end
      end
    end
  end
end
