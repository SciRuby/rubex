module Rubex
  module DataType
    class RubyObject
      include Helpers
      def to_s
        'VALUE'
      end

      def object?
        true
      end

      def p_formatter
        '%s'
      end
    end

  end
end
