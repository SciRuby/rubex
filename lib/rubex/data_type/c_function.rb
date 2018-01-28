module Rubex
  module DataType
    class CFunction
      include Helpers
      attr_reader :name, :type, :c_name
      attr_accessor :scope, :arg_list

      # FIXME: all attributes should be initialized upon class creation to maintain
      # sanity and consistency.
      def initialize(name, c_name, arg_list, type, scope)
        @name = name
        @c_name = c_name
        @arg_list = arg_list
        @type = type
        @scope = scope
      end

      def c_function?
        true
      end
    end
  end
end
