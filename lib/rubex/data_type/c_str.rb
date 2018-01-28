module Rubex
  module DataType
    class CStr
      include Helpers

      def cstr?
        true
      end

      def p_formatter
        '%s'
      end

      def from_ruby_object(arg)
        "StringValueCStr(#{arg})"
      end

      def to_ruby_object(arg)
        "rb_str_new_cstr(#{arg})"
      end
    end
  end
end
