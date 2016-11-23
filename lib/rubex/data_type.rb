module Rubex
  module DataType
    class RubyObject
      def to_s; "VALUE"; end
    end

    class CInt32
      def to_s; "int32_t"; end

      def to_ruby_function; "INT2NUM"; end

      def from_ruby_function; "NUM2INT"; end
    end
  end
end