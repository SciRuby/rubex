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

      def initialize name, c_name, type, value
        @name, @c_name, @type, @value = name, c_name, type, value
      end
    end
  end
end