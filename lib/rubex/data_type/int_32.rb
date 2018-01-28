module Rubex
  module DataType
    class Int32
      include IntHelpers
      def to_s
        'int32_t'
      end

      def from_ruby_object(arg)
        "(int32_t)NUM2INT(#{arg})"
      end

      def int32?
        true
      end

      def p_formatter
        '%d'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16?
          1
        elsif other.int32? || other.int?
          0
        else
          -1
        end
      end
    end
  end
end
