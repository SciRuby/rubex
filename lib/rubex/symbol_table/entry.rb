module Rubex
  module SymbolTable
    class Entry
      # Original name.
      attr_accessor :name
      # Equivalent name in C code.
      attr_accessor :c_name
      # Ctype of the the entry.
      attr_accessor :type
      # Default value of the entry, if any.
      attr_accessor :value
      # Is an extern entry
      attr_accessor :extern
      # Is a Ruby singleton method
      attr_accessor :singleton

      def initialize name, c_name, type, value
        @name, @c_name, @type, @value = name, c_name, type, value
      end

      def c_code local_scope
        c_name
      end

      def extern?; @extern; end

      def singleton?; @singleton; end
    end
  end
end
