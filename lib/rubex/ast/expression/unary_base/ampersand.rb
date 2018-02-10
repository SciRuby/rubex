module Rubex
  module AST
    module Expression
      class Ampersand < UnaryBase
        def analyse_types(local_scope)
          @expr.analyse_types local_scope
          @type = DataType::CPtr.new @expr.type
        end

        def c_code(local_scope)
          "&#{@expr.c_code(local_scope)}"
        end
      end
    end
  end
end
