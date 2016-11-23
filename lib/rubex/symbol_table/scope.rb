module Rubex
  module SymbolTable
    module Scope
      attr_accessor :entries, :outer_scope, :arg_entries

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
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

        attr_reader :name

        def initialize name
          name == 'Object' ? super(nil) : super
          @name = name
        end
      end

      class Local
        include Rubex::SymbolTable::Scope

        # args - Rubex::AST::ArgumentList. Creates sym. table entries for args.
        def declare_args args
          args.each do |arg|
            c_name = Rubex::ARGS_PREFIX + arg.name
            type = Rubex::TYPE_MAPPINGS[arg.type]
            entry = Rubex::SymbolTable::Entry.new arg.name, c_name, type 

            @entries[arg.name] = entry
            @arg_entries << entry
          end
        end
      end # class Local
    end
  end
end
