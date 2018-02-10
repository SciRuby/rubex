module Rubex
  module DataType
    class F64
      include FloatHelpers
      def to_s
        'double'
      end

      def to_ruby_object(arg)
        "rb_float_new(#{arg})"
      end

      def from_ruby_object(arg)
        "NUM2DBL(#{arg})"
      end

      def float64?
        true
      end

      def p_formatter
        '%f'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.int32? ||
           other.int64?     || other.int?    || other.uint8? || other.uint16? ||
           other.uint32?    || other.uint64? || other.float32?
          1
        elsif other.float64?
          0
        else
          -1
        end
      end
    end
  end
end
