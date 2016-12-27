module Rubex
  module DataType
    # Citations
    #   Printf arguments:
    #     http://www.thinkage.ca/english/gcos/expl/c/lib/printf.html
    module Boolean
      [
        :float?, :float32?, :float64?,
        :int?, :int8?, :int16?, :int32?, :int64?, 
        :uint?, :uint8?, :uint16?, :uint32?, :uint64?,
        :lint?, :ulint?, :llint?, :ullint?,
        :char?, :object?
      ].each do |dtype|
        define_method(dtype) { return false }
      end

      def == other
        self.class == other.class
      end
    end

    module IntHelpers
      include Boolean
      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def printf(arg); "printf(\"%d\", #{arg});"; end

      def int?; true; end
    end

    module UIntHelpers
      include Boolean
      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def printf(arg); "printf(\"%u\", #{arg});"; end

      def uint?; true; end
    end

    module FloatHelpers
      include Boolean
      def printf(arg); "printf(\"%f\", #{arg});"; end

      def float?; true; end
    end

    class RubyObject
      include Boolean
      def to_s; "VALUE"; end

      def printf(arg); "printf(\"%ld\", #{arg});"; end

      def object?; true; end
    end

    class Char
      def to_s; "char";  end

      def to_ruby_function(arg, literal=false)
        return "rb_str_new2(\"#{arg}\")" if literal
        
        "rb_str_new2(&#{arg})"
      end

      def from_ruby_function(arg); "(char)NUM2INT(#{arg})"; end

      def printf(arg); "printf(\"%c\", #{arg});" end

      def char?; true; end
    end

    # class CString
    #   # TODO: define string behaviour.
    # end

    class Int8
      include IntHelpers

      def to_s; "int8_t"; end

      def from_ruby_function(arg); "(int8_t)NUM2INT(#{arg})"; end

      def int8?; true; end
    end

    class Int16
      include IntHelpers
      def to_s; "int16_t"; end

      def from_ruby_function(arg); "(int16_t)NUM2INT(#{arg})"; end

      def int16?; true; end
    end

    class Int32
      include IntHelpers
      def to_s; "int32_t"; end

      def from_ruby_function(arg); "(int32_t)NUM2INT(#{arg})"; end

      def int32?; true; end
    end

    class Int64
      include IntHelpers
      def to_s; "int64_t"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2LONG(#{arg})"; end

      def printf(arg); "printf(\"%l\", #{arg});" end

      def int64?; true; end
    end

    class UInt8
      include UIntHelpers
      def to_s; "uint8_t"; end

      def from_ruby_function(arg); "(uint8_t)NUM2UINT(#{arg})"; end

      def uint8?; true; end
    end

    class UInt16
      include UIntHelpers
      def to_s; "uint16_t"; end

      def from_ruby_function(arg); "(uint16_t)NUM2UINT(#{arg})"; end

      def uint16?; true; end
    end

    class UInt32
      include UIntHelpers
      def to_s; "uint32_t"; end

      def from_ruby_function(arg); "(int32_t)NUM2UINT(#{arg})"; end

      def uint32?; true; end
    end

    class UInt64
      include UIntHelpers
      def to_s; "uint64_t"; end

      def to_ruby_function(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2UINT(#{arg})"; end

      def uint64?; true; end
    end

    class Int
      include IntHelpers
      def to_s; "int"; end

      def from_ruby_function(arg); "NUM2INT(#{arg})"; end

      def int?; true; end
    end

    class UInt
      include UIntHelpers
      def to_s; "unsigned int"; end

      def from_ruby_function(arg); "(unsigned int)NUM2UINT(#{arg})"; end

      def uint?; true; end
    end

    class LInt
      include IntHelpers
      def to_s; "long int"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2LONG(#{arg})"; end

      def lint?; true; end
    end

    class ULInt
      include UIntHelpers
      def to_s; "unsigned long int"; end

      def to_ruby_function(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2ULONG(#{arg})"; end

      def ulint?; true; end
    end

    class LLInt
      include IntHelpers
      def to_s; "long long int"; end

      def to_ruby_function(arg); "LL2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2LL(#{arg})"; end

      def llint?; true; end
    end

    class ULLInt
      include UIntHelpers
      def to_s; "unsigned long long int"; end

      def to_ruby_function(arg); "ULL2NUM(#{arg})"; end

      def from_ruby_function(arg); "NUM2ULL(#{arg})"; end

      def ullint?; true; end
    end

    class F32
      include FloatHelpers
      def to_s; "float"; end

      def to_ruby_function(arg); "rb_float_new((double)(#{arg}))"; end

      def from_ruby_function(arg); "(float)NUM2DBL(#{arg})"; end

      def float32?; true; end
    end

    class F64
      include FloatHelpers
      def to_s; "double"; end

      def to_ruby_function(arg); "rb_float_new(#{arg})"; end

      def from_ruby_function(arg); "NUM2DBL(#{arg})"; end

      def float64?; true; end
    end

    # TODO: How to store this in a Ruby class? Use BigDecimal?
    # class LF64
    #   def to_s; "long double"; end

    #   def to_ruby_function(arg); "INT2NUM"; end

    #   def from_ruby_function(arg); "(int32_t)NUM2INT"; end
    # end
  end
end