module Rubex
  module Helpers
    class << self
      def result_type_for left, right
        return left.dup if left == right
        return (left < right ? right.dup : left.dup)
      end

      def determine_dtype dtype_or_ptr
        if dtype_or_ptr[-1] == "*"
          Rubex::DataType::CPtr.new simple_dtype(dtype_or_ptr[0...-1])
        else
          simple_dtype(dtype_or_ptr)
        end
      end

      def simple_dtype dtype
        Rubex::CUSTOM_TYPES[dtype] || Rubex::TYPE_MAPPINGS[dtype].new
      end

      def create_arg_arrays scope
        scope.arg_entries.inject([]) do |array, arg|
          array << [arg.type.to_s, arg.c_name]
          array
        end
      end
    end

    module NodeTypeMethods
      [:expression?, :statement?, :literal?, :ruby_method?].each do |meth|
        define_method(meth) { false }
      end
    end
  end
end
