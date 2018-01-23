module Rubex
  module AST
    module Expression
      class Ampersand < UnaryBase
        attr_reader :type

        def analyse_statement local_scope
          @expr.analyse_statement local_scope
          @type = DataType::CPtr.new @expr.type
        end

        def c_code local_scope
          "&#{@expr.c_code(local_scope)}"
        end
      end
    end
  end
end
