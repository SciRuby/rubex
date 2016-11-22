module Rubex
  module SymbolTable
    module Scope
      class Klass
        attr_reader :name, :c_name
        attr_writer :ancestor

        def initialize name, c_name
          @name, @c_name = name, c_name
          # since Object does not need initialization.
          @ancestor = nil if @name == :Object 
        end
      end
    end
  end
end