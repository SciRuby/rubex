require 'rubex/helpers'
module Rubex
  module AST
    module Node
      class Base
        attr_reader :statements
        
        def initialize(statements)
          @statements = statements.flatten
        end
      end
    end
  end
end
