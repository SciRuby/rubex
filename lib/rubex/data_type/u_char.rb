module Rubex
  module DataType
    class UChar
      include Helpers

      def to_s
        'unsigned char'
      end

      def from_ruby_object(arg)
        "(unsigned char)NUM2INT(#{arg})"
      end

      def p_formatter
        '%d'
      end

      def uchar?
        true
      end

      def <=>(other)
        (other.char? || other.uchar?) ? 0 : 1
      end
    end
  end
end
