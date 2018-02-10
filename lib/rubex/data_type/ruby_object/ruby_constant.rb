module Rubex
  module DataType
    class RubyConstant < RubyObject
      attr_reader :name, :type

      def initialize(name)
        @name = name
        # FIXME: make this flexible so that consts set to primitive types can be
        #   easily converted to C types.
        @type = RubyObject.new
      end

      def ruby_constant?
        true
      end
    end
  end
end
