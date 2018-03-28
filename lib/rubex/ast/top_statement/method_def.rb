module Rubex
  module AST
    module TopStatement
      class MethodDef
        include Rubex::Helpers::Writers
        # Ruby name of the method.
        attr_reader :name
        # Method arguments. Accessor because arguments need to be modified in
        #   case of auxillary C functions of attach classes.
        attr_accessor :arg_list
        # The statments/expressions contained within the method.
        attr_reader :statements
        # Symbol Table entry.
        attr_reader :entry
        # Instance of Scope::Local for this method.
        attr_reader :scope
        # Variable name that identifies 'self'
        attr_reader :self_name

        def initialize(name, arg_list, statements)
          @name = name
          @arg_list = arg_list
          @statements = statements
          @self_name = Rubex::ARG_PREFIX + 'self'
        end

        def analyse_statement(outer_scope)
          @entry = outer_scope.find @name
          @scope = @entry.type.scope
          @scope.type = @entry.type
          @scope.self_name = @self_name
          @arg_list = @entry.type.arg_list
          @statements.each do |stat|
            stat.analyse_statement @scope
          end
        end

        # Option c_function - When set to true, certain code that is not required
        #   for Ruby methods will be generated too.
        def generate_code(code, c_function: false)
          code.block do
            generate_function_definition code, c_function: c_function
          end
        end

        def rescan_declarations(_scope)
          @statements.each do |stat|
            stat.respond_to?(:rescan_declarations) &&
              stat.rescan_declarations(@scope)
          end
        end

        private

        def generate_function_definition(code, c_function:)
          declare_types code, @scope
          declare_args code unless c_function
          declare_vars code, @scope
          declare_carrays code, @scope
          declare_ruby_objects code, @scope
          declare_temps code, @scope
          generate_arg_checking code unless c_function
          init_args code unless c_function
          declare_carrays_using_init_var_value code
          generate_statements code
        end

        def declare_args(code)
          @scope.arg_entries.each do |arg|
            code.declare_variable type: arg.type.to_s, c_name: arg.c_name
          end
        end

        def generate_statements(code)
          @statements.each do |stat|
            stat.generate_code code, @scope
          end
        end

        def init_args(code)
          @scope.arg_entries.each_with_index do |arg, i|
            code << arg.c_name + '=' + arg.type.from_ruby_object("argv[#{i}]") + ';'
            code.nl
          end
        end

        def declare_carrays_using_init_var_value(code)
          @scope.carray_entries.reject do |s|
            s.type.dimension.is_a?(Rubex::AST::Expression::Literal::Base)
          end. each do |arr|
            type = arr.type.type.to_s
            c_name = arr.c_name
            dimension = arr.type.dimension.c_code(@scope)
            value = arr.value.map { |a| a.c_code(@scope) } if arr.value
            code.declare_carray(type: type, c_name: c_name, dimension: dimension,
                                value: value)
          end
        end

        def generate_arg_checking(code)
          code << 'if (argc < ' + @scope.arg_entries.size.to_s + ')'
          code.block do
            code << %{rb_raise(rb_eArgError, "Need #{@scope.arg_entries.size} args, not %d", argc);\n}
          end
        end
      end
    end
  end
end
