module Rubex
  module DataType
    class CPtr
      include Helpers
      # The data type that this pointer is pointing to.
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def p_formatter
        '%s' if char_ptr?
      end

      def cptr?
        true
      end

      def to_s
        base_type = @type.base_type
        if base_type.c_function?
          ptr = ptr_level

          str = "#{base_type.type} (#{ptr} #{base_type.c_name})"
          str << '(' + base_type.arg_list.map { |e| e.type.to_s }.join(',') + ')'
        else
          t = @type
          str = '*'
          if t.cptr?
            str << '*'
            t = t.type
          end
          str.prepend t.to_s
          str
        end
      end

      def base_type
        return @type unless @type.is_a?(self.class)
        @type.base_type
      end

      def ptr_level
        temp = @type
        ptr = '*'
        while temp.cptr?
          ptr << '*'
          temp = @type.type
        end

        ptr
      end

      # from a Ruby function get a pointer to some value.
      def from_ruby_object(arg)
        return "StringValueCStr(#{arg})" if @type.char?
        arg
      end

      def to_ruby_object(arg)
        return "rb_str_new2(#{arg})" if @type.char?
        arg
      end

      def <=>(_other)
        -1
      end
    end
  end
end
