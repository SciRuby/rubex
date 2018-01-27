module Rubex
  module DataType
    class UInt64
      include UIntHelpers
      def to_s
        'uint64_t'
      end

      def to_ruby_object(arg)
        "ULONG2NUM(#{arg})"
      end

      def from_ruby_object(arg)
        "(int64_t)NUM2UINT(#{arg})"
      end

      def uint64?
        true
      end

      def p_formatter
        '%lu'
      end
    end
  end
end
