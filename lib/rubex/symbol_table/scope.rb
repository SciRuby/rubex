module Rubex
  module SymbolTable
    module Scope
      attr_accessor :entries, :outer_scope, :arg_entries, :return_type

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @arg_entries = []
        @return_type = nil
      end
    end
  end
end

module Rubex
  module SymbolTable
    module Scope
      class Klass
        include Rubex::SymbolTable::Scope

        attr_reader :name, :c_name

        def initialize name
          name == 'Object' ? super(nil) : super
          @name = name

          if Rubex::CLASS_MAPPINGS.has_key? name
            @c_name = Rubex::CLASS_MAPPINGS[name]
          else
            @c_name = Rubex::CLASS_PREFIX + name
          end
        end
      end

      class Local
        include Rubex::SymbolTable::Scope

        # args - Rubex::AST::ArgumentList. Creates sym. table entries for args.
        def declare_args args
          args.each do |arg|
            c_name = Rubex::ARGS_PREFIX + arg.name
            type = Rubex::TYPE_MAPPINGS[arg.type].new
            entry = Rubex::SymbolTable::Entry.new arg.name, c_name, type 

            @entries[arg.name] = entry
            @arg_entries << entry
          end
        end

        def [] entry
          @entries[entry] or raise "Symbol #{entry} does not exist in this scope."
        end
      end # class Local
    end
  end
end
