module Rubex
  module DataType
    class RubyObject
      def to_s; "VALUE"; end
    end

    class Char
      def to_s; "char";  end

      def to_ruby_function(arg) ; "rb_str_new2(&#{arg})"; end

      def from_ruby_function(arg); "(char)NUM2INT(#{arg})"; end
    end

    class Int8
      def to_s; "i8"; end

      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int8_t)NUM2INT(#{arg})"; end
    end

    class Int16
      def to_s; "i16"; end

      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int16_t)NUM2INT(#{arg})"; end
    end

    class Int32
      def to_s; "int32_t"; end

      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int32_t)NUM2INT(#{arg})"; end
    end

    class Int64
      def to_s; "i64"; end

      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2INT(#{arg})"; end
    end

    class UInt8
      def to_s; "ui8"; end

      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(uint8_t)NUM2UINT(#{arg})"; end
    end

    class UInt16
      def to_s; "ui16"; end

      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(uint16_t)NUM2UINT(#{arg})"; end
    end

    class UInt32
      def to_s; "ui32"; end

      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int32_t)NUM2UINT(#{arg})"; end
    end

    class UInt64
      def to_s; "ui64"; end

      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2UINT(#{arg})"; end
    end

    class Int
      def to_s; "int"; end

      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2INT(#{arg})"; end
    end

    class UInt
      def to_s; "unsigned int"; end

      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def from_ruby_function(arg); "(unsigned int)NUM2UINT(#{arg})"; end
    end

    class LInt
      def to_s; "long int"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2LONG(#{arg})"; end
    end

    class LLInt
      def to_s; "long long int"; end

      def to_ruby_function(arg); "LL2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2INT(#{arg})"; end
    end

    class F32
      def to_s; "float"; end

      def to_ruby_function(arg); "rb_float_new(#{arg})"; end

      def from_ruby_function(arg); "(float)NUM2DBL(#{arg})"; end
    end

    class F64
      def to_s; "double"; end

      def to_ruby_function(arg); "rb_float_new(#{arg})"; end

      def from_ruby_function(arg); "(float)NUM2DBL(#{arg})"; end
    end

    # TODO: How to store this in a Ruby class? Use BigDecimal?
    # class LF64
    #   def to_s; "long double"; end

    #   def to_ruby_function(arg); "INT2NUM"; end

    #   def from_ruby_function(arg); "(int32_t)NUM2INT"; end
    # end
  end
end