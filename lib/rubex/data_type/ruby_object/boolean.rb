module Rubex
  module DataType
    class Boolean < RubyObject
      include Helpers

      def bool?
        true
      end
    end
  end
end
