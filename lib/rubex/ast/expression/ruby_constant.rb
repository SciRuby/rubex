module Rubex
  module AST
    module Expression
      class RubyConstant < Base
        def initialize(name)
          @name = name
        end

        def analyse_types(_local_scope)
          @type = Rubex::DataType::RubyConstant.new @name
          c_name = Rubex::DEFAULT_CLASS_MAPPINGS[@name]
          @entry = Rubex::SymbolTable::Entry.new @name, c_name, @type, nil
        end

        def c_code(local_scope)
          if @entry.c_name # built-in constant.
            @entry.c_name
          else
            "rb_const_get(CLASS_OF(#{local_scope.self_name}), rb_intern(\"#{@entry.name}\"))"
          end
        end
      end # class RubyConstant
    end
  end
end
