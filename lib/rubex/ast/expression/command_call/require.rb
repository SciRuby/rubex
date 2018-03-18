module Rubex
  module AST
    module Expression
      class Require < Base
        def initialize args
          @args = args
        end

        def analyse_types(local_scope)
          raise "require can only support single string argument." if @args.size > 1
          if !@args[0].is_a?(Expression::Literal::StringLit)
            raise "Argument to require must be a string literal. not #{@args[0].class}."
          end
        end

        def generate_evaluation_code(code, local_scope)
          string = @args[0].instance_variable_get(:@name)          
          @c_code = "rb_funcall(rb_cObject, rb_intern(\"require\"), 1, rb_str_new2(\"#{string}\"))"
        end

        def c_code(_local_scope)
          @c_code
        end
      end
    end
  end
end
