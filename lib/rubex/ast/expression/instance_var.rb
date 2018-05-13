module Rubex
  module AST
    module Expression
      class InstanceVar < Base
        def initialize(name)
          @name = name
        end

        def analyse_types(local_scope)
          @type = DataType::RubyObject.new
          @has_temp = true
        end

        def generate_evaluation_code(code, local_scope)
          code << "#{@c_code} = rb_iv_get(#{local_scope.self_name}, \"#{@name}\");"
          code.nl
        end

        def generate_assignment_code(rhs, code, local_scope)
          code << "rb_iv_set(#{local_scope.self_name}, \"#{@name}\","
          code << "#{rhs.c_code(local_scope)});"
          code.nl
        end
        
        def c_code(local_scope)
          code = super
          code << @c_code
          code
        end
      end # class InstanceVar
    end # module Expression
  end # module AST
end # module Rubex
