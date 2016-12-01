module Rubex
  module AST
    class CBaseType
      attr_reader :type, :name, :value

      def initialize type, name, value=nil
        @type, @name, @value = type, name, value
      end
    end
  end
end