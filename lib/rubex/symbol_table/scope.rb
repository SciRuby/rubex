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
      attr_accessor :ruby_class_entries
      attr_accessor :ruby_method_entries

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
        @ruby_class_entries = []
        @ruby_method_entries = []
      end

      def check_entry name
        if @entries.has_key? name
          raise "Symbol name #{name} already exists in this scope."
        end
      end

      # vars - Rubex::AST::Statement::VarDecl/CPtrDecl
      def declare_var(name: "", c_name: "", type: nil, value: nil, extern: false)
        entry = Rubex::SymbolTable::Entry.new(name, c_name, type, value)

        entry.extern = extern
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
        entry = Rubex::SymbolTable::Entry.new(name, c_name, function.type, nil)
        entry.extern = function.extern
        @entries[name] = entry
        @cfunction_entries << entry
      end

      def add_ruby_obj name: , c_name:, value: nil
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

      def add_ruby_class name: , c_name:, scope:
        type = Rubex::DataType::RubyClass.new scope
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        @entries[name] = entry
        @ruby_class_entries << entry
      end

      # name: name of the method
      # c_name: c_name of the method
      # extern: whether it is defined within the Rubex script or in a scope
      #   outside the Rubex script.
      # scope: Which scope to add the method to. nil means the calling scope,
      #   :outer means that the method will added to a scope one level above
      #   the current scope.
      def add_ruby_method name:, c_name:, extern: false, scope: nil
        type = Rubex::DataType::RubyMethod.new name, c_name
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        entry.extern = extern
        if scope == :outer
          @outer_scope.entries[name] = entry
        else
          @entries[name] = entry
          @ruby_method_entries << entry
        end
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

        attr_reader :name
        attr_accessor :include_files #TODO: this should probably not be here.

        def initialize name, outer_scope
          super(outer_scope)
          @name = name
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
