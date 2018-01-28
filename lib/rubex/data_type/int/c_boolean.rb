module Rubex
  module DataType
    class CBoolean < Int
      def cbool?
        true
      end

      def to_ruby_object(arg)
        Rubex::C_MACRO_INT2BOOL + '(' + arg + ')'
      end
    end
  end
end
