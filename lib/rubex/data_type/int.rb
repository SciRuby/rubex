module Rubex
  module DataType
    class Int
      include IntHelpers
      def to_s
        'int'
      end

      def from_ruby_object(arg)
        "NUM2INT(#{arg})"
      end

      def int?
        true
      end

      def p_formatter
        '%d'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16?
          1
        elsif other.int? || other.int32?
          0
        else # other is int64 or greater
          -1
        end
      end
    end
  end
end
