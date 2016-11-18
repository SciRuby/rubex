module Rubex
  module AST
    class CBaseType
      attr_reader :base_type, :name_string

      def initialize base_type, name_string
        @base_type, @name_string = base_type, name_string
      end
    end
  end
end