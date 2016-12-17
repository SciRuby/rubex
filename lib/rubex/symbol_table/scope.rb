module Rubex
  module SymbolTable
    module Scope
      attr_accessor :entries
      attr_accessor :outer_scope
      attr_accessor :arg_entries
      attr_accessor :return_type
      attr_accessor :var_entries

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @arg_entries = []
        @var_entries = []
        @return_type = nil
      end

      def check_entry name
        if @entries.has_key? name
          raise "Symbol name #{name} already exists in this scope."
        end
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
            c_name = Rubex::ARG_PREFIX + arg.name
            type = Rubex::TYPE_MAPPINGS[arg.type].new
            entry = Rubex::SymbolTable::Entry.new arg.name, c_name, type, arg.value 

            name = arg.name
            check_entry name
            @entries[name] = entry
            @arg_entries << entry
          end
        end

        # vars - [Rubex::AST::Statement::ArgumentDeclaration]
        def declare_vars vars
          vars.each do |var|
            c_name = Rubex::VAR_PREFIX + var.name
            entry = Rubex::SymbolTable::Entry.new( 
              var.name, c_name, var.type, var.value)

            name = var.name
            check_entry name
            @entries[name] = entry
            @var_entries << entry
          end
        end

        def add_var name, type, value
          c_name = Rubex::VAR_PREFIX + name
          entry = Rubex::SymbolTable::Entry.new(
            name, c_name, type, value)
          @entries[name] = entry
        end

        def [] entry
          @entries[entry] or raise(Rubex::SymbolNotFoundError, 
            "Symbol #{entry} does not exist in this scope.")
        end
      end # class Local
    end
  end
end
