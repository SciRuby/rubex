module Rubex
  module DataType
    class UInt8
      include UIntHelpers
      def to_s
        'uint8_t'
      end

      def from_ruby_object(arg)
        "(uint8_t)NUM2UINT(#{arg})"
      end

      def uint8?
        true
      end

      def p_formatter
        '%u'
      end
    end
  end
end
