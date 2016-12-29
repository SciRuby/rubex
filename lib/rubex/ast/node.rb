module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        @statements = statements.is_a?(Array) ? statements : [statements]
      end

      def add_child child
        @statements.concat child
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object'
        analyse_statements
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
        code.nl
      end

      def analyse_statements
        @statements.each do |stat|
          stat.analyse_statements @scope
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
    end
  end
end
