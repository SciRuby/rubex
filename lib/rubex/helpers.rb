require 'rubex/ast'
require_relative 'helpers/writers'
require_relative 'helpers/node_type_methods'

module Rubex
  module Helpers
    class << self
      def construct_function_argument(data)
        if data[:variables][0][:ident].is_a?(Hash)
          Rubex::AST::Expression::FuncPtrArgDeclaration.new(data)
        else
          Rubex::AST::Expression::ArgDeclaration.new(data)
        end
      end

      def to_lhs_type(lhs, rhs)
        if lhs.type.object?
          rhs.to_ruby_object
        elsif !lhs.type.object? && rhs.type.object?
          rhs.from_ruby_object(lhs)
        else
          rhs
        end
      end

      def result_type_for(left, right)
        return left.dup if left == right

        (left < right ? right.dup : left.dup)
      rescue ArgumentError => e
        raise Rubex::TypeError, e.to_s
      end

      def determine_dtype(data, ptr_level)
        if ptr_level && ptr_level[-1] == '*'
          ptr_level = ptr_level.dup
          base_type = Rubex::DataType::CPtr.new simple_dtype(data)
          ptr_level.chop!

          ptr_level.each_char do |_star|
            base_type = Rubex::DataType::CPtr.new base_type
          end

          base_type
        else
          simple_dtype(data)
        end
      end

      def simple_dtype(dtype)
        if dtype.is_a?(Rubex::DataType::CFunction)
          dtype
        else
          begin
            Rubex::CUSTOM_TYPES[dtype] || Rubex::TYPE_MAPPINGS[dtype].new
          rescue StandardError
            raise Rubex::TypeError, "Type #{dtype} not previously declared."
          end
        end
      end

      def create_arg_arrays(arg_list)
        arg_list.each_with_object([]) do |arg, array|
          entry = arg.entry
          c_name = entry.type.base_type.c_function? ? '' : entry.c_name
          array << [entry.type.to_s, c_name]
        end
      end
    end
  end
end
