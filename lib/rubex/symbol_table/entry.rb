module Rubex
  module SymbolTable
    class Entry
      # Original name.
      attr_accessor :name
      # Equivalent name in C code.
      attr_accessor :c_name
      # Ctype of the the entry.
      attr_accessor :type

      def initialize name, c_name, type
        @name, @c_name, @type = name, c_name, type
      end
    end
  end
end