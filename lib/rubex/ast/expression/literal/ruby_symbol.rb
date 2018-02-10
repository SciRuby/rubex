module Rubex
  module AST
    module Expression
      module Literal
        class RubySymbol < Base
          def initialize(name)
            super(name[1..-1])
            @type = Rubex::DataType::RubySymbol.new
          end

          def generate_evaluation_code(_code, _local_scope)
            @c_code = "ID2SYM(rb_intern(\"#{@name}\"))"
          end

          def c_code(_local_scope)
            @c_code
          end
        end
      end
    end
  end
end
