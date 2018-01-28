module Rubex
  module DataType
    class ULInt
      include UIntHelpers
      def to_s
        'unsigned long int'
      end

      def to_ruby_object(arg)
        "ULONG2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "NUM2ULONG(#{arg})"
      end

      def ulint?
        true
      end

      def p_formatter
        '%lu'
      end

      def <=>(other)
        if other.char? || other.int8? || other.int16? || other.int32? || other .int64? || other.uint8? || other.uint16? || other.uint32? || other.int?
          1
        elsif other.ulint?
          0
        else
          -1
        end
      end
    end
  end
end
