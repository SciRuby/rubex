module Rubex
  module AST
    class CBaseType
      attr_reader :type, :name

      def initialize type, name
        @type, @name = type, name
      end
    end
  end
end