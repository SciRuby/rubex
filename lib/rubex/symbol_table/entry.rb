module Rubex
  module SymbolTable
    class Entry
      attr_accessor :name, :c_name, :type

      def initialize name, c_name, type
        @name, @c_name, @type = name, c_name, type
      end
    end
  end
end