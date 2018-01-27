module Rubex
  module DataType
    # Citations
    #   Printf arguments:
    #     http://www.thinkage.ca/english/gcos/expl/c/lib/printf.html
    module Helpers
      include ::Comparable
      %i[
    float? float32? float64?
    int? int8? int16? int32? int64?
    uint? uint8? uint16? uint32? uint64?
    lint? ulint? llint? ullint?
    char? object? bool? carray? cbool?
    cptr? nil_type? struct_or_union?
    alias_type? string? cstr? ruby_class?
    ruby_method? c_function? ruby_constant? void?
    ruby_string? uchar? ruby_array? ruby_hash?
  ].each do |dtype|
        define_method(dtype) { return false }
      end

      def ==(other)
        self.class == other.class
      end

      def to_ruby_object(arg)
        arg
      end

      def from_ruby_object(arg)
        arg
      end

      def base_type
        self
      end

      # Helper function to know if a dtype is a char pointer.
      def char_ptr?
        cptr? && base_type.char?
      end

      def c_function_ptr?
        cptr? && base_type.c_function?
      end
    end
  end
end
