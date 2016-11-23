module Rubex
  module SymbolTable
    module Scope
      attr_accessor :entries, :outer_scope, :var_entries, :ruby_function_entries,
        :arg_entries

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @var_entries = []
        @ruby_function_entries = []
        @arg_entries = []
      end
    end
  end
end

module Rubex
  module SymbolTable
    module Scope
      class Klass
        include Rubex::SymbolTable::Scope
        attr_accessor :name, :cname

        def initialize name
          super
          @name = name
        end
      end

      class Local
        include Rubex::SymbolTable::Scope

        def initialize
          
        end
      end
    end
  end
end
