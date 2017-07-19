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
        :char?, :object?, :bool?, :carray?, :cbool?,
        :cptr?, :nil_type?, :struct_or_union?,
        :alias_type?, :string?, :cstr?, :ruby_class?,
        :ruby_method?, :c_function?, :ruby_constant?, :void?,
        :ruby_string?
      ].each do |dtype|
        define_method(dtype) { return false }
      end

      def == other
        self.class == other.class
      end

      def to_ruby_object(arg); arg;  end

      def from_ruby_object(arg); arg; end

      def base_type; self; end
    end

    module IntHelpers
      include Helpers
      def to_ruby_object(arg); "INT2NUM(#{arg})"; end
    end

    module UIntHelpers
      include Helpers
      def to_ruby_object(arg); "UINT2NUM(#{arg})"; end
    end

    module FloatHelpers
      include Helpers
    end

    class CBoolean
      include Helpers

      def cbool?; true; end

      def to_ruby_object arg
        Rubex::C_MACRO_INT2BOOL + "(" + arg + ")"
      end
    end

    class Void
      include Helpers

      def void?; true; end

      def to_s; "void"; end
    end

    class RubyObject
      include Helpers
      def to_s; "VALUE"; end

      def object?; true; end

      def p_formatter; "%s"; end
    end

    class RubySymbol < RubyObject
      def ruby_symbol?; true; end
    end

    class RubyString < RubyObject
      def ruby_string?; true; end
    end

    class Char
      include Helpers
      def to_s; "char";  end

      def to_ruby_object(arg, literal=false)
        return "rb_str_new2(\"#{arg[1]}\")" if literal

        "rb_str_new2(&#{arg})"
      end

      def from_ruby_object(arg); "(char)NUM2INT(#{arg})"; end

      def p_formatter; "%c"; end

      def char?; true; end

      def <=> other
        if other.char?
          return 0
        else
          return 1
        end
      end
    end

    class Int8
      include IntHelpers

      def to_s; "int8_t"; end

      def from_ruby_object(arg); "(int8_t)NUM2INT(#{arg})"; end

      def int8?; true; end

      def p_formatter; "%d"; end

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

      def from_ruby_object(arg); "(int16_t)NUM2INT(#{arg})"; end

      def int16?; true; end

      def p_formatter; "%d"; end

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

      def from_ruby_object(arg); "(int32_t)NUM2INT(#{arg})"; end

      def int32?; true; end

      def p_formatter; "%d"; end

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

      def to_ruby_object(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_object(arg); "(int64_t)NUM2LONG(#{arg})"; end

      def p_formatter; "%ld"; end

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

      def from_ruby_object(arg); "(uint8_t)NUM2UINT(#{arg})"; end

      def uint8?; true; end

      def p_formatter; "%u"; end
    end

    class UInt16
      include UIntHelpers
      def to_s; "uint16_t"; end

      def from_ruby_object(arg); "(uint16_t)NUM2UINT(#{arg})"; end

      def uint16?; true; end

      def p_formatter; "%u"; end
    end

    class UInt32
      include UIntHelpers
      def to_s; "uint32_t"; end

      def from_ruby_object(arg); "(int32_t)NUM2UINT(#{arg})"; end

      def uint32?; true; end

      def p_formatter; "%u"; end
    end

    class UInt64
      include UIntHelpers
      def to_s; "uint64_t"; end

      def to_ruby_object(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_object(arg); "(int64_t)NUM2UINT(#{arg})"; end

      def uint64?; true; end

      def p_formatter; "%lu"; end
    end

    class Int
      include IntHelpers
      def to_s; "int"; end

      def from_ruby_object(arg); "NUM2INT(#{arg})"; end

      def int?; true; end

      def p_formatter; "%d"; end

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

      def from_ruby_object(arg); "(unsigned int)NUM2UINT(#{arg})"; end

      def uint?; true; end

      def p_formatter; "%u"; end

      def <=> other
        if other.char? || other.int8? || other.int16? || other.uint8? || other.uint16?
          return 1
        elsif other.uint? || other.int? || other.int32? || other.uint32?
          return 0
        else
          return -1
        end
      end
    end

    class LInt
      include IntHelpers
      def to_s; "long int"; end

      def to_ruby_object(arg); "LONG2NUM(#{arg})"; end

      def from_ruby_object(arg); "NUM2LONG(#{arg})"; end

      def lint?; true; end

      def p_formatter; "%ld"; end
    end

    class ULInt
      include UIntHelpers
      def to_s; "unsigned long int"; end

      def to_ruby_object(arg); "ULONG2NUM(#{arg})"; end

      def from_ruby_object(arg); "NUM2ULONG(#{arg})"; end

      def ulint?; true; end

      def p_formatter; "%lu"; end

      def <=> other
        if other.char? || other.int8? || other.int16? || other.int32? ||
          other .int64? || other.uint8? || other.uint16? || other.uint32? ||
          other.int?
          return 1
        elsif other.ulint?
          return 0
        else
          return -1
        end
      end
    end

    class Size_t < ULInt
      def to_s
        "size_t"
      end
    end

    class LLInt
      include IntHelpers
      def to_s; "long long int"; end

      def to_ruby_object(arg); "LL2NUM(#{arg})"; end

      def from_ruby_object(arg); "NUM2LL(#{arg})"; end

      def llint?; true; end

      def p_formatter; "%ll"; end
    end

    class ULLInt
      include UIntHelpers
      def to_s; "unsigned long long int"; end

      def to_ruby_object(arg); "ULL2NUM(#{arg})"; end

      def from_ruby_object(arg); "NUM2ULL(#{arg})"; end

      def ullint?; true; end

      def p_formatter; "%llu"; end
    end

    class F32
      include FloatHelpers
      def to_s; "float"; end

      def to_ruby_object(arg); "rb_float_new((double)(#{arg}))"; end

      def from_ruby_object(arg); "(float)NUM2DBL(#{arg})"; end

      def float32?; true; end

      def p_formatter; "%f"; end

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

      def to_ruby_object(arg); "rb_float_new(#{arg})"; end

      def from_ruby_object(arg); "NUM2DBL(#{arg})"; end

      def float64?; true; end

      def p_formatter; "%f"; end

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
      attr_reader :type # FIXME: Make this base_type to make it more explicit.

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

      def base_type
        @type
      end
    end

    class CPtr
      include Helpers
      # The data type that this pointer is pointing to.
      attr_reader :type

      def initialize type
        @type = type
      end

      def cptr?; true; end

      def to_s
        base_type = @type.base_type
        if base_type.c_function?
          ptr = ptr_level

          str = "#{base_type.type.to_s} (#{ptr} #{base_type.c_name.to_s})"
          str << "(" + base_type.arg_list.map { |e| e.type.to_s }.join(',') + ")"
        else
          t = @type
          str = "*"
          if t.cptr?
            str << "*"
            t = t.type
          end
          str.prepend t.to_s
          str
        end
      end

      def base_type
        return @type if !@type.is_a?(self.class)
        return @type.base_type
      end

      def ptr_level
        temp = @type
        ptr = "*"
        while temp.cptr?
          ptr << "*"
          temp = @type.type
        end

        ptr
      end

      # from a Ruby function get a pointer to some value.
      def from_ruby_object arg
        return "StringValueCStr(#{arg})" if @type.char?
        arg
      end

      def <=> other
        return -1
      end
    end

    class Boolean < RubyObject
      include Helpers

      def bool?; true; end
    end

    class TrueType < Boolean;  end

    class FalseType < Boolean;  end

    class NilType < RubyObject
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

    # FIXME: Find out a better way to generically find the old type of a typedef
    #   when the new type is encountered. Should cover cases where the new type
    #   is aliased with some other name too. In other words, reach the actual
    #   type in the most generic way possible without too many checks.
    class TypeDef
      include Helpers
      attr_reader :type, :old_type, :new_type

      def initialize old_type, new_type, type
        @old_type, @new_type, @type = old_type, new_type, type
      end

      def alias_type?; true; end

      def to_s
        @new_type.to_s
      end

      def base_type
        @old_type
      end
    end

    class CStr
      include Helpers

      def cstr?; true; end
      
      def p_formatter; "%s"; end

      def from_ruby_object arg
        "StringValueCStr(#{arg})"
      end

      def to_ruby_object arg
        "rb_str_new_cstr(#{arg})"
      end
    end

    class RubyConstant
      include Helpers

      attr_reader :name, :type

      def initialize name
        @name = name
        # FIXME: make this flexible so that consts set to primitive types can be
        #   easily converted to C types.
        @type = RubyObject.new 
      end

      def ruby_constant?; true; end
    end

    class RubyClass < RubyConstant
      include Helpers

      attr_reader :name, :c_name, :scope, :ancestor

      def initialize name, c_name, scope, ancestor
        @name, @c_name, @scope, @ancestor = name, c_name, scope, ancestor
      end

      def ruby_class?; true; end
    end

    class RubyMethod
      include Helpers

      attr_reader :name, :c_name, :type
      attr_accessor :scope, :arg_list

      def initialize name, c_name
        @name, @c_name, = name, c_name
        @type = RubyObject.new
      end

      def ruby_method?; true; end
    end

    class CFunction
      include Helpers
      attr_reader :name, :type, :c_name
      attr_accessor :scope, :arg_list

      # FIXME: all attributes should be initialized upon class creation to maintain
      # sanity and consistency.
      def initialize name, c_name, arg_list, type
        @name, @c_name, @arg_list, @type = name, c_name, arg_list, type
      end

      def c_function?; true; end
    end
    # TODO: How to store this in a Ruby class? Use BigDecimal?
    # class LF64
    #   def to_s; "long double"; end

    #   def to_ruby_object(arg); "INT2NUM"; end

    #   def from_ruby_object(arg); "(int32_t)NUM2INT"; end
    # end
  end
end
