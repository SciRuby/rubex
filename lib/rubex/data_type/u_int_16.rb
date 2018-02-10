module Rubex
  module DataType
    class UInt16
      include UIntHelpers
      def to_s
        'uint16_t'
      end

      def from_ruby_object(arg)
        "(uint16_t)NUM2UINT(#{arg})"
      end

      def uint16?
        true
      end

      def p_formatter
        '%u'
      end
    end
  end
end
