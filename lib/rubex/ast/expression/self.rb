module Rubex
  module AST
    module Expression
      class Self < Base
        def c_code(local_scope)
          local_scope.self_name
        end

        def type
          Rubex::DataType::RubyObject.new
        end
      end # class Self
    end
  end
end
