module Rubex
  module AST
    module TopStatement
      class RubyMethodDef < MethodDef
        attr_reader :singleton

        def initialize(name, arg_list, statements, singleton: false)
          super(name, arg_list, statements)
          @singleton = singleton
        end

        def analyse_statement(local_scope)
          super
          @entry.singleton = @singleton
        end

        def generate_code(code)
          code.write_ruby_method_header(type: @entry.type.type.to_s,
                                        c_name: @entry.c_name)
          super
        end

        def ==(other)
          self.class == other.class && @name == other.name &&
            @c_name == other.c_name && @arg_list == other.arg_list &&
            @statements == other.statements && @entry == other.entry &&
            @type == other.type
        end
      end

    end
  end
end
