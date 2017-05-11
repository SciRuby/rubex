module Rubex
  module AST
    class Node
      attr_reader :statements

      def initialize statements
        @statements = statements.flatten
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object', nil
        add_top_statements_to_object_scope
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

      def add_top_statements_to_object_scope
        temp = []
        combined_statements = []
        @statements.each do |stmt|
          if stmt.is_a?(TopStatement::Klass) || stmt.is_a?(TopStatement::CBindings)
            if !temp.empty?
              object_klass = TopStatement::Klass.new('Object', @scope, temp)
              combined_statements << object_klass
            end

            combined_statements << stmt
            temp = []
          else
            temp << stmt
          end
        end

        if !temp.empty?
          combined_statements << TopStatement::Klass.new('Object', @scope, temp)
        end

        @statements = combined_statements
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
        @statements.grep(Rubex::AST::TopStatement::Klass).each do |klass|
          klass.statements.grep(Rubex::AST::TopStatement::RubyMethodDef).each do |meth|
            code.write_ruby_method_header(
              type: meth.entry.type.type.to_s, c_name: meth.entry.c_name)
            code.colon
          end

          klass.statements.grep(Rubex::AST::TopStatement::CFunctionDef).each do |meth|
            code.write_c_method_header(
              type: meth.entry.type.type.to_s, 
              c_name: meth.entry.c_name, 
              args: Helpers.create_arg_arrays(meth.entry.type.scope))
            code.colon
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
            # The top level scope in Ruby is Object. The Object class's immediate
            # ancestor is also Object. Hence, it is important to set the class
            # scope and ancestor scope of Object as Object, and make sure that
            # the same scope object is used for 'Object' class every single time
            # throughout the compilation process.
            if stat.name != 'Object'
              ancestor_scope = @scope.find(stat.ancestor)&.type&.scope || @scope
              klass_scope = Rubex::SymbolTable::Scope::Klass.new(
                name, ancestor_scope)
            else
              ancestor_scope = @scope
              klass_scope = @scope
            end
            c_name = c_name_for_class stat.name

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
        code.write_func_declaration type: "void", c_name: name, args: []
        code.write_c_method_header type: "void", c_name: name, args: []
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
                if meth.singleton?
                  code.write_singleton_method klass: entry.c_name,
                    method_name: meth.name, method_c_name: meth.c_name
                else
                  code.write_instance_method klass: entry.c_name, 
                    method_name: meth.name, method_c_name: meth.c_name
                end
              end
            end
          end
        end
      end
    end # class Node
  end # module AST
end # module Rubex
