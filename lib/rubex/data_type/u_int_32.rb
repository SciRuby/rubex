module Rubex
  module DataType
    class UInt32
      include UIntHelpers
      def to_s
        'uint32_t'
      end

      def from_ruby_object(arg)
        "(int32_t)NUM2UINT(#{arg})"
      end

      def uint32?
        true
      end

      def p_formatter
        '%u'
      end
    end
  end
end
