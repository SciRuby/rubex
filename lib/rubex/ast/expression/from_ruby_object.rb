module Rubex
  module AST
    module Expression
      # internal node for converting from ruby object.
      class FromRubyObject < CoerceObject
        # expr - Expression to convert
        # from_node - LHS expression. Of type Rubex::AST::Expression
        def initialize(expr, from_node)
          @expr = expr
          @type = @expr.type
          @from_node = from_node
        end

        def c_code(local_scope)
          @from_node.type.from_ruby_object(@expr.c_code(local_scope)).to_s
        end
      end
    end
  end
end
