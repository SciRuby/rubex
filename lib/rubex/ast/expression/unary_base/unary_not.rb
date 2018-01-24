module Rubex
  module AST
    module Expression

      class UnaryNot < UnaryBase
        attr_reader :type

        def c_code local_scope
          code = @expr.c_code(local_scope)
          if @type.object?
            "rb_funcall(#{code}, rb_intern(\"!\"), 0)"
          else
            "!#{code}"
          end
        end
      end

    end
  end
end
