module Rubex
  module AST
    module Expression

      # internal node for converting to ruby object.
      class ToRubyObject < CoerceObject
        attr_reader :type

        def initialize expr
          @expr = expr
          @type = Rubex::DataType::RubyObject.new
        end

        def c_code local_scope
          t = @expr.type
          t = (t.c_function? || t.alias_type?) ? t.type : t
          "#{t.to_ruby_object(@expr.c_code(local_scope))}"
        end
      end
    end
  end
end
