module Rubex
  module DataType
    class Void
      include Helpers

      def void?
        true
      end

      def to_s
        'void'
      end
    end
  end
end
