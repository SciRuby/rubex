module Rubex
  module Helpers
    class << self
      def result_type_for left, right
        result = nil
        if left == right
          result = left.class.new
        end

        if left.float64?
          result = Rubex::DataType::F64.new if (right.float32? || right.int?)
        end

        result
      end
    end

    module NodeTypeMethods
      [:expression?, :statement?, :literal?, :ruby_method?].each do |meth|
        define_method(meth) { false }
      end
    end
  end
end