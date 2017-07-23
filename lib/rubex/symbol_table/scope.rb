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
      attr_accessor :c_method_entries
      attr_accessor :type_entries
      attr_accessor :ruby_class_entries
      attr_accessor :ruby_method_entries
      attr_accessor :ruby_constant_entries
      attr_accessor :self_name
      attr_accessor :temp_entries
      attr_accessor :free_temp_entries
      attr_reader   :klass_name, :name

      def initialize outer_scope=nil
        @outer_scope = outer_scope
        @entries = {}
        @arg_entries = []
        @var_entries = []
        @type = nil
        @ruby_obj_entries = []
        @carray_entries = []
        @sue_entries = []
        @c_method_entries = []
        @type_entries = []
        @ruby_class_entries = []
        @ruby_method_entries = []
        @ruby_constant_entries = []
        @self_name = ""
        @klass_name = ""
        @temp_entries = []
        @free_temp_entries = []
        @temp_counter = 0
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

        entry
      end

      def declare_sue name:, c_name:, type:, extern:
        entry = Rubex::SymbolTable::Entry.new(
          name, c_name, type, nil)
        entry.extern = extern
        @entries[name] = entry
        @sue_entries << entry
        @type_entries << entry

        entry
      end

      def declare_type type:
        entry = Rubex::SymbolTable::Entry.new(nil, nil, type, nil)
        @type_entries << entry

        entry
      end

      def add_ruby_obj name: , c_name:, value: nil
        entry = Rubex::SymbolTable::Entry.new(
          name, c_name, Rubex::DataType::RubyObject.new, value)
        @entries[name] = entry
        @ruby_obj_entries << entry

        entry
      end

      # Add a C array to the current scope.
      def add_carray name: ,c_name: ,dimension: ,type: ,value: nil
        type = Rubex::DataType::CArray.new dimension, type
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, value
        @entries[name] = entry
        @carray_entries << entry

        entry
      end

      # Add a Ruby class to the current scope.
      def add_ruby_class name: , c_name:, scope:, ancestor:
        type = Rubex::DataType::RubyClass.new name, c_name, scope, ancestor
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        @entries[name] = entry
        @ruby_class_entries << entry

        entry
      end

      def add_c_method name:, c_name:, type:, extern: false
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        entry.extern = extern
        @entries[name] = entry
        @c_method_entries << entry

        entry
      end

      # name: name of the method
      # c_name: c_name of the method
      # extern: whether it is defined within the Rubex script or in a scope
      #   outside the Rubex script.
      def add_ruby_method name:, c_name:, extern: false
        type = Rubex::DataType::RubyMethod.new name, c_name
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        entry.extern = extern
        @entries[name] = entry
        @ruby_method_entries << entry unless extern

        entry
      end

      # allocate a temp and return its c_name
      def allocate_temp type
        if @free_temp_entries.empty?
          @temp_counter += 1
          c_name = Rubex::TEMP_PREFIX + @temp_counter.to_s
          entry = Rubex::SymbolTable::Entry.new c_name, c_name, type, 
            Expression::Literal::CNull.new('NULL')
          @entries[c_name] = entry
          @temp_entries << entry
        else
          entry = @free_temp_entries.pop
          c_name = entry.c_name
        end

        c_name
      end

      # release a temp of name 'c_name' for reuse
      def release_temp c_name
        @free_temp_entries << @entries[c_name]
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
        attr_accessor :include_files #TODO: this should probably not be here.

        def initialize name, outer_scope
          super(outer_scope)
          @name = name
          @klass_name = @name
          @include_files = []
        end

        def object_scope
          temp = self
          while temp.outer_scope != nil
            temp = temp.outer_scope
          end

          temp
        end
      end # class Klass

      class Local
        include Rubex::SymbolTable::Scope

        def initialize name, outer_scope
          super(outer_scope)
          @name = name
          @klass_name = outer_scope.klass_name
        end

        # args - Rubex::AST::ArgumentList. Creates sym. table entries for args.
        def add_arg name:, c_name:, type:, value:
          entry = Rubex::SymbolTable::Entry.new name, c_name, type, value
          check_entry name
          @entries[name] = entry
          @arg_entries << entry

          entry
        end
      end # class Local

      class StructOrUnion
        include Rubex::SymbolTable::Scope
        # FIXME: Change scope structure to identify struct scopes by name too.

        def initialize name, outer_scope
          super(outer_scope)
          @klass_name = outer_scope.klass_name
          @name = name
        end
      end # class StructOrUnion
    end
  end
end
