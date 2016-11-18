module Rubex
  module AST
    class Expression
      class Addition
        attr_reader :left, :right

        def initialize left, right
          @left, @right = left, right
        end
      end
    end
  end
end
