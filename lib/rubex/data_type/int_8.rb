module Rubex
  module DataType
    class Int8
      include IntHelpers

      def to_s
        'int8_t'
      end

      def from_ruby_object(arg)
        "(int8_t)NUM2INT(#{arg})"
      end

      def int8?
        true
      end

      def p_formatter
        '%d'
      end

      def <=>(other)
        if other.char?
          1
        elsif other.int8?
          0
        else
          -1
        end
      end
    end
  end
end
