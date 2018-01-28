module Rubex
  module DataType
    class Int16
      include IntHelpers
      def to_s
        'int16_t'
      end

      def from_ruby_object(arg)
        "(int16_t)NUM2INT(#{arg})"
      end

      def int16?
        true
      end

      def p_formatter
        '%d'
      end

      def <=>(other)
        if other.char? || other.int8?
          1
        elsif other.int16?
          0
        else
          -1
        end
      end
    end
  end
end
