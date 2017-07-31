module Rubex
  module Helpers
    class << self
      def to_lhs_type lhs, rhs
        if lhs.type.object?
          return rhs.to_ruby_object
        elsif lhs.type.object? && !rhs.type.object?
          return rhs.from_ruby_object
        end  
      end

      def result_type_for left, right
        begin
          return left.dup if left == right
          return (left < right ? right.dup : left.dup)
        rescue ArgumentError => e
          raise Rubex::TypeError, e.to_s
        end
      end

      def determine_dtype data, ptr_level
        if ptr_level && ptr_level[-1] == "*"
          ptr_level = ptr_level.dup
          base_type = Rubex::DataType::CPtr.new simple_dtype(data)
          ptr_level.chop!

          ptr_level.each_char do |star|
            base_type = Rubex::DataType::CPtr.new base_type
          end

          return base_type
        else
          return simple_dtype(data)
        end
      end

      def simple_dtype dtype
        if dtype.is_a?(Rubex::DataType::CFunction)
          dtype
        else
          begin
            Rubex::CUSTOM_TYPES[dtype] || Rubex::TYPE_MAPPINGS[dtype].new  
          rescue
            raise Rubex::TypeError, "Type #{dtype} not previously declared."
          end          
        end
      end

      def create_arg_arrays arg_list
        arg_list.inject([]) do |array, arg|
          entry = arg.entry
          c_name = entry.type.base_type.c_function? ? "" : entry.c_name
          array << [entry.type.to_s, c_name]
          array
        end
      end
    end

    module Writers
      def declare_temps code, scope
        scope.temp_entries.each do |var|
          code.declare_variable type: var.type.to_s, c_name: var.c_name
        end  
      end

      def declare_vars code, scope
        scope.var_entries.each do |var|
          if var.type.base_type.c_function?
            code.declare_func_ptr var: var
          else
            code.declare_variable type: var.type.to_s, c_name: var.c_name
          end
        end
      end

      def declare_carrays code, scope
        scope.carray_entries.select { |s|
          s.type.dimension.is_a? Rubex::AST::Expression::Literal::Base
        }. each do |arr|
          type = arr.type.type.to_s
          c_name = arr.c_name
          dimension = arr.type.dimension.c_code(@scope)
          value = arr.value.map { |a| a.c_code(@scope) } if arr.value
          code.declare_carray(type: type, c_name: c_name, dimension: dimension,
            value: value)
        end
      end

      def declare_types code, scope
        scope.type_entries.each do |entry|
          type = entry.type

          if type.alias_type?
            base = type.old_type
            if base.respond_to?(:base_type) && base.base_type.c_function?
              func = base.base_type
              str = "typedef #{func.type} (#{type.old_type.ptr_level} #{type.new_type})"
              str << "(" + func.arg_list.map { |e| e.type.to_s }.join(',') + ")"
              str << ";"
              code << str
            else
              code << "typedef #{type.old_type} #{type.new_type};"
            end
          elsif type.struct_or_union? && !entry.extern?
            code << sue_header(entry)
            code.block(sue_footer(entry)) do
              declare_vars code, type.scope
              declare_carrays code, type.scope
              declare_ruby_objects code, type.scope
            end
          end
          code.nl
        end
      end

      def sue_header entry
        type = entry.type
        str = "#{type.kind} #{type.name}"
        if !entry.extern
          str.prepend "typedef "
        end

        str
      end

      def sue_footer entry
        str =
        if entry.extern
          ";"
        else
          " #{entry.type.c_name};"
        end

        str
      end

      def declare_ruby_objects code, scope
        scope.ruby_obj_entries.each do |var|
          code.declare_variable type: var.type.to_s, c_name: var.c_name
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
