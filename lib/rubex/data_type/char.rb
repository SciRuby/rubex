module Rubex
  module DataType
    class Char
      include Helpers
      def to_s
        'char'
      end

      def to_ruby_object(arg, _literal = false)
        "#{Rubex::C_FUNC_CHAR2RUBYSTR}(#{arg})"
      end

      def from_ruby_object(arg)
        "(char)NUM2INT(#{arg})"
      end

      def p_formatter
        '%c'
      end

      def char?
        true
      end

      def <=>(other)
        other.char? ? 0 : 1
      end
    end
  end
end
