module Rubex
  module DataType
    class RubyClass < RubyConstant
      attr_reader :name, :c_name, :scope, :ancestor

      def initialize(name, c_name, scope, ancestor)
        @name = name
        @c_name = c_name
        @scope = scope
        @ancestor = ancestor
      end

      def ruby_class?
        true
      end
    end
  end
end
