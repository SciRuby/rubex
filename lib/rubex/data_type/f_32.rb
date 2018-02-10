module Rubex
  module DataType
    class F32
      include FloatHelpers
      def to_s
        'float'
      end

      def to_ruby_object(arg)
        "rb_float_new((double)(#{arg}))"
      end

      def from_ruby_object(arg)
        "(float)NUM2DBL(#{arg})"
      end

      def float32?
        true
      end

      def p_formatter
        '%f'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.int32? ||
           other.int64?     || other.int? || other.uint8? || other.uint16? ||
           other.uint32?    || other.uint64?
          1
        elsif other.float32?
          0
        else # other is float64
          -1
        end
      end
    end
  end
end
