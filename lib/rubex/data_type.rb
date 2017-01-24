module Rubex
  module DataType
    # Citations
    #   Printf arguments:
    #     http://www.thinkage.ca/english/gcos/expl/c/lib/printf.html
    module Helpers
      include ::Comparable
      [
        :float?, :float32?, :float64?,
        :int?, :int8?, :int16?, :int32?, :int64?,
        :uint?, :uint8?, :uint16?, :uint32?, :uint64?,
        :lint?, :ulint?, :llint?, :ullint?,
        :char?, :object?, :bool?, :carray?,
        :cptr?, :nil_type?, :struct_or_union?,
        :alias_type?
      ].each do |dtype|
        define_method(dtype) { return false }
      end

      def == other
        self.class == other.class
      end

      def to_ruby_function(arg); arg;  end

      def from_ruby_function(arg); arg; end
    end

    module IntHelpers
      include Helpers
      def to_ruby_function(arg); "INT2NUM(#{arg})"; end

      def printf(arg); "printf(\"%d\", #{arg});"; end
    end

    module UIntHelpers
      include Helpers
      def to_ruby_function(arg); "UINT2NUM(#{arg})"; end

      def printf(arg); "printf(\"%u\", #{arg});"; end
    end

    module FloatHelpers
      include Helpers
      def printf(arg); "printf(\"%f\", #{arg});"; end
    end

    class Boolean
      include Helpers

      def bool?; true; end
    end

    class RubyObject
      include Helpers
      def to_s; "VALUE"; end

      def printf(arg); "printf(\"%ld\", #{arg});"; end

      def object?; true; end
    end

    class Char
      include Helpers
      def to_s; "char";  end

      def to_ruby_function(arg, literal=false)
        return "rb_str_new2(\"#{arg[1]}\")" if literal

        "rb_str_new2(&#{arg})"
      end

      def from_ruby_function(arg); "(char)NUM2INT(#{arg})"; end

      def printf(arg); "printf(\"%c\", #{arg});" end

      def char?; true; end

      def <=> other
        if other.char?
          return 0
        else
          return 1
        end
      end
    end

    # class CString
    #   # TODO: define string behaviour.
    # end

    class Int8
      include IntHelpers

      def to_s; "int8_t"; end

      def from_ruby_function(arg); "(int8_t)NUM2INT(#{arg})"; end

      def int8?; true; end

      def <=> other
        if other.char?
          return 1
        elsif other.int8?
          return 0
        else
          return -1
        end
      end
    end

    class Int16
      include IntHelpers
      def to_s; "int16_t"; end

      def from_ruby_function(arg); "(int16_t)NUM2INT(#{arg})"; end

      def int16?; true; end

      def <=> other
        if other.char? || other.int8?
          return 1
        elsif other.int16?
          return 0
        else
          return -1
        end
      end
    end

    class Int32
      include IntHelpers
      def to_s; "int32_t"; end

      def from_ruby_function(arg); "(int32_t)NUM2INT(#{arg})"; end

      def int32?; true; end

      def <=> other
        if other.char? || other.int8? || other.int16?
          return 1
        elsif other.int32? || other.int?
          return 0
        else
          return -1
        end
      end
    end

    class Int64
      include IntHelpers
      def to_s; "int64_t"; end

      def to_ruby_function(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_function(arg); "(int64_t)NUM2LONG(#{arg})"; end

      def printf(arg); "printf(\"%ld\", #{arg});" end

      def int64?; true; end

      def <=> other
        if other.char? || other.int8? || other.int16? || other.int32? ||
          other.int?
          return 1
        elsif other.int64?
          return 0
        else
          return -1
        end
      end
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

      def <=> other
        if other.char? || other.int8? || other.int16?
          return 1
        elsif other.int? || other.int32?
          return 0
        else # other is int64 or greater
          return -1
        end
      end
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

      def <=> other
        if other.char?     || other.int8?   || other.int16? || other.int32? ||
          other.int64?     || other.int?    || other.uint8? || other.uint16?||
          other.uint32?    || other.uint64?
          return 1
        elsif other.float32?
          return 0
        else # other is float64
          return -1
        end
      end

    end

    class F64
      include FloatHelpers
      def to_s; "double"; end

      def to_ruby_function(arg); "rb_float_new(#{arg})"; end

      def from_ruby_function(arg); "NUM2DBL(#{arg})"; end

      def float64?; true; end

      def <=> other
        if other.char? || other.int8?   || other.int16? || other.int32? ||
          other.int64?     || other.int?    || other.uint8? || other.uint16?||
          other.uint32?    || other.uint64? || other.float32?
          return 1
        elsif other.float64?
          return 0
        else
          return -1
        end
      end
    end

    class CArray
      include Helpers
      # Dimension of the array
      attr_reader :dimension
      # Type of elements stored in array
      attr_reader :type

      def initialize dimension, type
        @dimension, @type = dimension, type
      end

      def carray?; true; end

      def <=> other
        if self.class == other.class
          @type <=> other.type
        else
          @type <=> other
        end
      end
    end

    class CPtr
      include Helpers
      attr_reader :type

      def initialize type
        @type = type
      end

      def cptr?; true; end

      def to_s
        t = @type
        str = "*"
        if t.cptr?
          str << "*"
          t = t.type
        end
        str.prepend t.to_s
        str
      end

      def to_ruby_function arg
        return "StringValueCStr(#{arg})" if @type.char?
        arg
      end
    end

    class TrueType < Boolean;  end

    class FalseType < Boolean;  end

    class NilType
      include Helpers

      def nil_type?; true; end
    end

    class CStructOrUnion
      include Helpers
      attr_reader :kind, :name, :c_name, :scope

      def initialize kind, name, c_name, scope
        @kind, @name, @c_name, @scope = kind, name, c_name, scope
      end

      def struct_or_union?; true; end

      def to_s; "#{@c_name}"; end
    end

    class CFunction
      include Helpers
      attr_reader :name, :args, :type
      attr_accessor :c_name

      def initialize name, args, type
        @name, @args, @type = name, args, type
      end
    end

    class TypeDef
      include Helpers
      attr_reader :type, :old_name, :new_name

      def initialize old_name, new_name, type
        @old_name, @new_name, @type = old_name, new_name, type
      end

      def alias_type?; true; end

      def to_s
        @new_name
      end
    end
    # TODO: How to store this in a Ruby class? Use BigDecimal?
    # class LF64
    #   def to_s; "long double"; end

    #   def to_ruby_function(arg); "INT2NUM"; end

    #   def from_ruby_function(arg); "(int32_t)NUM2INT"; end
    # end
  end
end
