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
      attr_accessor :global_entries
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
        @global_entries = []
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

      def declare_type type:, extern:
        entry = Rubex::SymbolTable::Entry.new(nil, nil, type, nil)
        entry.extern = extern
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
      def add_ruby_class name: , c_name:, scope:, ancestor:, extern:
        type = Rubex::DataType::RubyClass.new name, c_name, scope, ancestor
        entry = Rubex::SymbolTable::Entry.new name, c_name, type, nil
        entry.extern = extern
        @entries[name] = entry
        @ruby_class_entries << entry

        entry
      end

      def add_c_method name:, c_name:, scope:, arg_list:, return_type:, extern: false
        type = Rubex::DataType::CFunction.new(
          name, c_name, arg_list, return_type, scope)
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
      def add_ruby_method name:, c_name:, scope:, arg_list:, extern: false
        type = Rubex::DataType::RubyMethod.new name, c_name, scope, arg_list
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
        attr_accessor :begin_block_callbacks

        def initialize name, outer_scope
          super(outer_scope)
          @name = name
          @klass_name = @name
          @include_files = []
          @begin_block_callbacks = []
        end

        def object_scope
          temp = self
          while temp.outer_scope != nil
            temp = temp.outer_scope
          end

          temp
        end

        # Stores CFunctionDef nodes that represent begin block callbacks.
        def add_begin_block_callback func
          @begin_block_callbacks << func
        end
      end # class Klass

      class Local
        include Rubex::SymbolTable::Scope
        attr_reader :begin_block_counter

        def initialize name, outer_scope
          super(outer_scope)
          @name = name
          @klass_name = outer_scope.klass_name
          @begin_block_counter = 0
        end

        # args - Rubex::AST::ArgumentList. Creates sym. table entries for args.
        def add_arg name:, c_name:, type:, value:
          entry = Rubex::SymbolTable::Entry.new name, c_name, type, value
          check_entry name
          @entries[name] = entry
          @arg_entries << entry

          entry
        end

        def found_begin_block
          @begin_block_counter += 1
        end
      end # class Local

      class BeginBlock
        attr_reader :name, :outer_scope

        def initialize name, outer_scope
          @outer_scope = outer_scope
          @name = name
          @block_entries = []
        end

        def upgrade_symbols_to_global
          @block_entries.uniq!
          @block_entries.each do |entry|
            entry.c_name = Rubex::GLOBAL_PREFIX + @name + entry.c_name
            @outer_scope.global_entries << entry
          end

          remove_global_from_local_entries
        end

        # IMPORTANT NOTE TO PROGRAMMER:
        #
        # A problem with the BeginBlock is that in the Ruby world, it must share
        # scope with the method above and below it. However, when translating to
        # C, the begin block must be put inside its own C function, which is then
        # sent as a callback to rb_protect().
        #
        # As a result, it is necesary to 'upgrade' the local variables present
        # inside the begin block to C global variables so that they can be shared
        # between the callback C function encapsulating the begin block and the 
        # ruby method that has a begin block defined inside it.
        #
        # Now, since variables must be shared, it is also necessary to share the
        # scopes between these functions. Therefore, the BeginBlock scope uses
        # method_missing to capture whatever methods calls it has received and 
        # redirect those to @outer_scope, which is the scope of the method that
        # contains the begin block. Whenever a method call to @outer_scope returns
        # a SymbolTable::Entry object, that object is read to check if it is a
        # variable. If yes, it is added into the @block_entries Array which
        # stores the entries that need to be upgraded to C global variables.
        #
        # Now as a side effect of this behaviour, the various *_entries Arrays
        # of @outer_scope get carried forward into this begin block callback.
        # Therefore these variables get declared inside the begin block callback
        # as well. So whenever one of these Arrays is called for this particular
        # scope, we return an empty array so that nothing gets declared.
        def method_missing meth, *args, &block
          return [] if meth == :var_entries
          ret = @outer_scope.send(meth, *args, &block)
          if ret.is_a?(Rubex::SymbolTable::Entry)
            if !ret.extern?
              if !ret.type.c_function? && !ret.type.ruby_method? &&
                 !ret.type.ruby_class?
                @block_entries << ret
              end
            end
          end

          ret
        end

      private

        def remove_global_from_local_entries
          @outer_scope.arg_entries      -= @outer_scope.global_entries
          @outer_scope.var_entries      -= @outer_scope.global_entries
          @outer_scope.ruby_obj_entries -= @outer_scope.global_entries
          @outer_scope.carray_entries   -= @outer_scope.global_entries
          @outer_scope.sue_entries      -= @outer_scope.global_entries
          @outer_scope.c_method_entries -= @outer_scope.global_entries
          @outer_scope.type_entries     -= @outer_scope.global_entries
        end
      end # class BeginBlock

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
