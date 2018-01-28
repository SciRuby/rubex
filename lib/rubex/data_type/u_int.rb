module Rubex
  module DataType
    class UInt
      include UIntHelpers
      def to_s
        'unsigned int'
      end

      def from_ruby_object(arg)
        "(unsigned int)NUM2UINT(#{arg})"
      end

      def uint?
        true
      end

      def p_formatter
        '%u'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.uint8? || other.uint16?
          1
        elsif other.uint? || other.int? || other.int32? || other.uint32?
          0
        else
          -1
        end
      end
    end
  end
end
