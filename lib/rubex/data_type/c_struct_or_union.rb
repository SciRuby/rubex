module Rubex
  module DataType
    class CStructOrUnion
      include Helpers
      attr_reader :kind, :name, :c_name, :scope

      def initialize(kind, name, c_name, scope)
        @kind = kind
        @name = name
        @c_name = c_name
        @scope = scope
      end

      def struct_or_union?
        true
      end

      def to_s
        @c_name.to_s
      end
    end
  end
end
