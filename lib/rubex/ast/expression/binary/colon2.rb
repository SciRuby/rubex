module Rubex
  module AST
    module Expression
      class Colon2 < Base
        attr_reader :lhs, :rhs
        
        def initialize lhs, rhs
          @lhs = lhs
          @rhs = rhs
        end

        def analyse_types local_scope
          @type = DataType::RubyObject.new
        end

        def generate_evaluation_code code, local_scope
          @c_code = recursive_scoping_generation @lhs, @rhs, "rb_const_get(CLASS_OF(#{local_scope.self_name}), rb_intern(\"#{@lhs}\"))"
        end

        def recursive_scoping_generation lhs, rhs, c_str
          if rhs.is_a?(Colon2)
            recursive_scoping_generation rhs.lhs, rhs.rhs, "rb_const_get(#{c_str}, rb_intern(\"#{rhs.lhs}\"))"
          else
            "rb_const_get(#{c_str}, rb_intern(\"#{rhs}\"))"
          end
        end
        
        def c_code local_scope
          super + @c_code
        end
      end
    end
  end
end
