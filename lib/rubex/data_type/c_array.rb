module Rubex
  module DataType
    class CArray
      include Helpers
      # Dimension of the array
      attr_reader :dimension
      # Type of elements stored in array
      attr_reader :type # FIXME: Make this base_type to make it more explicit.

      def initialize(dimension, type)
        @dimension = dimension
        @type = type
      end

      def carray?
        true
      end

      def <=>(other)
        @type <=>
          if self.class == other.class
            other.type
          else
            other
          end
      end

      def base_type
        @type
      end
    end
  end
end
