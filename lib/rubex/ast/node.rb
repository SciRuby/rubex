module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        @statements = statements.flatten
      end

      def add_child child
        @statements.concat child
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object', nil
        add_top_level_ruby_methods_to_object_class_scope
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

      def add_top_level_ruby_methods_to_object_class_scope
        ruby_methods = @statements.select do |s| 
          s.is_a?(Rubex::AST::TopStatement::RubyMethodDef)
        end
        
        unless ruby_methods.empty?      
          @statements.delete_if do |s|
            s.is_a?(Rubex::AST::TopStatement::RubyMethodDef)
          end

          @statements << Rubex::AST::TopStatement::Klass.new(
            'Object', 'Object', ruby_methods
          )
        end
      end

      def generate_preamble code
        code << "#include <ruby.h>\n"
        code << "#include <stdint.h>\n"
        @scope.include_files.each do |name|
          code << "#include #{name}\n"
        end
        declare_types code
        write_function_declarations code
        code.nl
      end

      def write_function_declarations code
        @statements.each do |stat|
          if stat.is_a? Rubex::AST::TopStatement::Klass
            statements = stat.statements
            statements.each do |meth|
              if meth.is_a? Rubex::AST::TopStatement::RubyMethodDef
                code.write_func_declaration(meth.entry.type.type.to_s,
                  meth.entry.c_name)
              end
            end
          end
        end
      end

      def declare_types code
        @scope.type_entries.each do |entry|
          type = entry.type

          if type.alias_type?
            code << "typedef #{type.type.to_s} #{type.to_s};"
          end
          code.nl
        end
      end

      def analyse_statements
        create_symtab_entries_for_top_statements
        @statements.each do |stat|
          stat.analyse_statements @scope
        end
      end

      def create_symtab_entries_for_top_statements
        @statements.each do |stat|
          if stat.is_a? Rubex::AST::TopStatement::Klass
            name = stat.name
            ancestor_scope =
            if stat.ancestor != 'Object'
              @scope.find(stat.ancestor).type.scope
            else
              @scope
            end
            c_name = c_name_for_class stat.name
            klass_scope = Rubex::SymbolTable::Scope::Klass.new name, ancestor_scope

            @scope.add_ruby_class(name: name, c_name: c_name, scope: klass_scope,
              ancestor: ancestor_scope)
          end
        end
      end

      def c_name_for_class name
        c_name =
        if Rubex::DEFAULT_CLASS_MAPPINGS.has_key? name
          Rubex::DEFAULT_CLASS_MAPPINGS[name]
        else
          Rubex::RUBY_CLASS_PREFIX + name
        end

        c_name
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
          @statements.each do |top_stmt|
            if top_stmt.is_a?(TopStatement::Klass) && top_stmt.name != 'Object'
              entry = @scope.find top_stmt.name
              code.declare_variable type: "VALUE", c_name: entry.c_name
            end
          end
          code.nl

          @statements.each do |top_stmt|
            if top_stmt.is_a?(TopStatement::Klass) && top_stmt.name != 'Object'
              entry = top_stmt.entry
              ancestor_entry = @scope.find top_stmt.ancestor.name
              c_name = ancestor_entry ? ancestor_entry.c_name : 'rb_cObject'
              rhs = "rb_define_class(\"#{entry.name}\", #{c_name})"
              code.init_variable lhs: entry.c_name, rhs: rhs
            end
          end
          code.nl

          @statements.each do |top_stmt|
            if top_stmt.is_a? TopStatement::Klass
              entry = @scope.find top_stmt.name
              klass_scope = entry.type.scope
              klass_scope.ruby_method_entries.each do |meth|
                code.define_instance_method klass: entry.c_name, 
                  method_name: meth.name, method_c_name: meth.c_name
              end
            end
          end
        end
      end
    end # class Node
  end # module AST
end # module Rubex
