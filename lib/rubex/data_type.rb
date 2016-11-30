module Rubex
  module DataType
    # Citations
    #   Printf arguments:
    #     http://www.thinkage.ca/english/gcos/expl/c/lib/printf.html
    module IntHelpers
      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def cprintf(arg); "printf(%d, #{arg});"; end
    end

    module UIntHelpers
      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def cprintf(arg); "printf(%u, #{arg});"; end
    end

    class RubyObject
      def to_s; "VALUE"; end

      def cprintf(arg); "printf(%ld, #{arg});"; end
    end

    class Char
      def to_s; "char";  end

      def to_ruby_function(arg) ; "rb_str_new2(&#{arg})"; end

      def from_ruby_function(arg); "(char)NUM2INT(#{arg})"; end

      def cprintf(arg); "printf(%c, #{arg});" end
    end

    class Int8
      include IntHelpers

      def to_s; "int8_t"; end

      def from_ruby_function(arg); "(int8_t)NUM2INT(#{arg})"; end
    end

    class Int16
      include IntHelpers
      def to_s; "int16_t"; end

      def from_ruby_function(arg); "(int16_t)NUM2INT(#{arg})"; end
    end

    class Int32
      include IntHelpers
      def to_s; "int32_t"; end

      def from_ruby_function(arg); "(int32_t)NUM2INT(#{arg})"; end
    end

    class Int64
      def to_s; "int64_t"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2LONG(#{arg})"; end

      def cprintf(arg); "printf(%l, #{arg});" end
    end

    class UInt8
      include UIntHelpers
      def to_s; "uint8_t"; end

      def from_ruby_function(arg); "(uint8_t)NUM2UINT(#{arg})"; end
    end

    class UInt16
      include UIntHelpers
      def to_s; "uint16_t"; end

      def from_ruby_function(arg); "(uint16_t)NUM2UINT(#{arg})"; end
    end

    class UInt32
      include UIntHelpers
      def to_s; "uint32_t"; end

      def from_ruby_function(arg); "(int32_t)NUM2UINT(#{arg})"; end
    end

    class UInt64
      def to_s; "uint64_t"; end

      def to_ruby_function(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2UINT(#{arg})"; end
    end

    class Int
      include IntHelpers
      def to_s; "int"; end

      def from_ruby_function(arg); "NUM2INT(#{arg})"; end
    end

    class UInt
      include UIntHelpers
      def to_s; "unsigned int"; end

      def from_ruby_function(arg); "(unsigned int)NUM2UINT(#{arg})"; end
    end

    class LInt
      def to_s; "long int"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2LONG(#{arg})"; end
    end

    class ULInt
      def to_s; "unsigned long int"; end

      def to_ruby_function(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2ULONG(#{arg})"; end
    end

    class LLInt
      def to_s; "long long int"; end

      def to_ruby_function(arg); "LL2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2LL(#{arg})"; end
    end

    class ULLInt
      def to_s; "unsigned long long int"; end

      def to_ruby_function(arg); "ULL2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2ULL(#{arg})"; end
    end

    class F32
      def to_s; "float"; end

      def to_ruby_function(arg); "rb_float_new((double)(#{arg}))"; end

      def from_ruby_function(arg); "(float)NUM2DBL(#{arg})"; end
    end

    class F64
      def to_s; "double"; end

      def to_ruby_function(arg); "rb_float_new(#{arg})"; end

      def from_ruby_function(arg); "NUM2DBL(#{arg})"; end
    end

    # TODO: How to store this in a Ruby class? Use BigDecimal?
    # class LF64
    #   def to_s; "long double"; end

    #   def to_ruby_function(arg); "INT2NUM"; end

    #   def from_ruby_function(arg); "(int32_t)NUM2INT"; end
    # end
  end
end