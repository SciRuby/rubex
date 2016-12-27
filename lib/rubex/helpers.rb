module Rubex
  module Helpers
    class << self
      def result_type_for left, right
        return left.class.new if left == right
        return (left < right ? right.class.new : left.class.new)
      end
    end

    module NodeTypeMethods
      [:expression?, :statement?, :literal?, :ruby_method?].each do |meth|
        define_method(meth) { false }
      end
    end
  end
end