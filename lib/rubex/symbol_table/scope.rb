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
      attr_accessor :sue_entries
      attr_accessor :cfunction_entries
      attr_accessor :type_entries

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @arg_entries = []
        @var_entries = []
        @type = nil
        @ruby_obj_entries = []
        @carray_entries = []
        @sue_entries = []
        @cfunction_entries = []
        @type_entries = []
      end

      def check_entry name
        if @entries.has_key? name
          raise "Symbol name #{name} already exists in this scope."
        end
      end

      # vars - Rubex::AST::Statement::VarDecl/CPtrDecl
      def declare_var var
        entry = Rubex::SymbolTable::Entry.new(
          var.name, var.c_name, var.type, var.value)

        name = var.name
        entry.extern = var.extern
        check_entry name
        @entries[name] = entry
        @var_entries << entry
      end

      def declare_sue var
        entry = Rubex::SymbolTable::Entry.new(
          var.name, var.type.c_name, var.type, nil)
        entry.extern = var.extern
        @entries[var.name] = entry
        @sue_entries << entry
        @type_entries << entry
      end

      def declare_type type
        entry = Rubex::SymbolTable::Entry.new(nil, nil, type.type, nil)
        # @entries[type.name] = entry
        @type_entries << entry
      end

      def declare_cfunction function
        name = function.name
        if function.extern
          c_name = name
        else
          c_name = Rubex::C_FUNC_PREFIX + name
        end
        function.type.c_name = c_name
        entry = Rubex::SymbolTable::Entry.new(name, c_name, function.type, nil)
        entry.extern = function.extern
        @entries[name] = entry
        @cfunction_entries << entry
      end

      def add_ruby_obj name, value
        c_name = Rubex::VAR_PREFIX + name
        entry = Rubex::SymbolTable::Entry.new(
          name, c_name, Rubex::DataType::RubyObject.new, value)
        @entries[name] = entry
        @ruby_obj_entries << entry
      end

      def add_carray name, dimension, carray_list, type
        c_name = Rubex::ARRAY_PREFIX + name
        value = carray_list
        type = Rubex::DataType::CArray.new dimension, type
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

      # Find an entry in this scope or the ones above it recursively.
      def find name
        return recursive_find(name, self)
      end

    private
      def recursive_find name, scope
        if scope
          if scope.has_entry?(name)
            return scope[name]
          else
            return recursive_find(name, scope.outer_scope)
          end
        end

        return nil
      end
    end # module Scope
  end # module SymbolTable
end # module Rubex

module Rubex
  module SymbolTable
    module Scope
      class Klass
        include Rubex::SymbolTable::Scope

        attr_reader :name, :c_name
        attr_accessor :include_files

        def initialize name
          name == 'Object' ? super(nil) : super
          @name = name

          if Rubex::CLASS_MAPPINGS.has_key? name
            @c_name = Rubex::CLASS_MAPPINGS[name]
          else
            @c_name = Rubex::CLASS_PREFIX + name
          end
          @include_files = []
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
      end # class Local

      class StructOrUnion
        include Rubex::SymbolTable::Scope
      end # class StructOrUnion
    end
  end
end
