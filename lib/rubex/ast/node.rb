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
        generate_symbol_table_entries
        analyse_statements
        generate_preamble code
        generate_code code
        generate_init_method target_name, code
      end

      # Pretty print the AST
      def pp
        tree = {}
        tree[self.class.to_s] = {}
        tree[self.class.to_s]['statements'] = {}
        stats = tree[self.class.to_s]['statements']

        recursive_pp stats, self

        tree
      end

     private

      def recursive_pp hash, object        
        (object.instance_variables).each do |var|
          if var == :@statements
            object.instance_variable_get(var).each do |stat|
              hash[stat.class.to_s] = {}
              hash[stat.class.to_s]['statements'] = {}
              temp = hash[stat.class.to_s]['statements']
              recursive_pp temp, stat
            end
          else
            hash[var.to_s] = object.instance_variable_get(var).inspect
          end
        end
      end

      def generate_preamble code
        code << "#include <ruby.h>\n"
        code << "#include <stdint.h>\n"
        code.nl
      end

      def generate_symbol_table_entries
        @statements.each do |stat|
          stat.generate_symbol_table_entries @scope
        end
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