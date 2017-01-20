module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        @statements = statements
      end

      def add_child child
        @statements.concat child
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object'
        analyse_statements
        rescan_declarations @scope
        generate_preamble code
        generate_code code
        generate_init_method target_name, code
      end

      def == other
        self.class == other.class
      end

     private

      def generate_preamble code
        code << "#include <ruby.h>\n"
        code << "#include <stdint.h>\n"
        @scope.include_files.each do |name|
          code << "#include <#{name}.h>\n"
        end
        declare_extern_c_structs code
        declare_extern_c_functions code
        code.nl
      end

      def declare_extern_c_functions code
        @scope.cfunction_entries.each do |func|
          code << "#{func.type.type} #{func.c_name} (#{func.type.args.join(',')});"
          code.nl
        end
      end

      def declare_vars code, scope
        scope.var_entries.each do |var|
          code.declare_variable var
        end
      end

      def declare_carrays code, scope
        scope.carray_entries.select { |s|
          s.type.dimension.is_a? Rubex::AST::Expression::Literal
        }. each do |arr|
          code.declare_carray arr, @scope
        end
      end

      def declare_extern_c_structs code
        @scope.sue_entries.each do |sue|
          code << "typedef #{sue.type.kind} #{sue.name}"
          code.block(" #{sue.name};") do
            declare_vars code, sue.type.scope
            declare_carrays code, sue.type.scope
          end
          code.nl
        end
      end

      def analyse_statements
        @statements.each do |stat|
          stat.analyse_statements @scope
        end
      end

      def rescan_declarations scope
        @statements.each do |stat|
          stat.respond_to?(:rescan_declarations) and
            stat.rescan_declarations(@scope)
        end
      end

      def generate_code code
        @statements.each do |stat|
          stat.generate_code code
        end
      end

      def generate_init_method target_name, code
        name = "Init_#{target_name}"
        code.new_line
        code.write_func_declaration "void", name, "void"
        code.write_func_definition_header "void", name, "void"
        code.block do
          @statements.each do |stat|
            if stat.is_a? Rubex::AST::RubyMethodDef
              code.define_instance_method_under @scope, stat.name, stat.c_name
            end
          end
        end
      end
    end # class Node
  end # module AST
end # module Rubex
