module Rubex
  module SymbolTable
    module Scope
      attr_accessor :entries
      attr_accessor :outer_scope
      attr_accessor :arg_entries
      attr_accessor :type
      attr_accessor :var_entries
      attr_accessor :ruby_obj_entries
      attr_accessor :carray_entries

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @arg_entries = []
        @var_entries = []
        @type = nil
        @ruby_obj_entries = []
        @carray_entries = []
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

        # vars - Rubex::AST::Statement::VarDecl
        def declare_var var
          c_name = Rubex::VAR_PREFIX + var.name
          entry = Rubex::SymbolTable::Entry.new(
            var.name, c_name, var.type, var.value)

          name = var.name
          check_entry name
          @entries[name] = entry
          @var_entries << entry
        end

        def add_ruby_obj name, value
          c_name = Rubex::VAR_PREFIX + name
          entry = Rubex::SymbolTable::Entry.new(
            name, c_name, Rubex::DataType::RubyObject.new, value)
          @entries[name] = entry
          @ruby_obj_entries << entry
        end

        def add_carray carray_ref, carray_list, type
          name = carray_ref.name
          c_name = Rubex::ARRAY_PREFIX + name
          value = carray_list
          type = Rubex::DataType::CArray.new carray_ref.pos, type
          entry = Rubex::SymbolTable::Entry.new name, c_name, type, value
          @entries[name] = entry
          @carray_entries << entry
        end

        def [] entry
          @entries[entry] or raise(Rubex::SymbolNotFoundError,
            "Symbol #{entry} does not exist in this scope.")
        end

        def has_entry? entry
          !!@entries[entry]
        end
      end # class Local
    end
  end
end
