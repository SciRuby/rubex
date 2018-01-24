module Rubex
  module AST
    module Expression
      module Literal
        class ArrayLit < Base
          include Enumerable

          attr_accessor :c_array

          def each(&block)
            @array_list.each(&block)
          end

          def initialize(array_list)
            @array_list = array_list
            @subexprs = []
          end

          def analyse_types(local_scope)
            @has_temp = true
            @type = DataType::RubyObject.new
            @array_list.map! do |e|
              e.analyse_types local_scope
              e = e.to_ruby_object
              @subexprs << e
              e
            end
          end

          def generate_evaluation_code(code, local_scope)
            code << "#{@c_code} = rb_ary_new2(#{@array_list.size});"
            code.nl
            @array_list.each do |e|
              code << "rb_ary_push(#{@c_code}, #{e.c_code(local_scope)});"
              code.nl
            end
          end

          def generate_disposal_code(code)
            code << "#{@c_code} = 0;"
            code.nl
          end

          def c_code(_local_scope)
            @c_code
          end
        end # class ArrayLit
      end
    end
  end
end
