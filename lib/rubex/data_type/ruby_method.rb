module Rubex
  module DataType
    class RubyMethod
      include Helpers

      attr_reader :name, :c_name, :type
      attr_accessor :scope, :arg_list

      def initialize(name, c_name, scope, arg_list)
        @name = name
        @c_name = c_name
        @scope = scope
        @arg_list = arg_list
        @type = RubyObject.new
      end

      def ruby_method?
        true
      end
    end
  end
end
