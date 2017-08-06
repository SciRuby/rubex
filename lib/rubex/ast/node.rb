module Rubex
  module AST
    class Node
      include Rubex::Helpers::Writers
      attr_reader :statements

      def initialize statements
        @statements = statements.flatten
      end

      def process_statements target_name, code
        @scope = Rubex::SymbolTable::Scope::Klass.new 'Object', nil
        add_top_statements_to_object_scope
        analyse_statement
        rescan_declarations @scope
        generate_preamble code
        generate_code code
        generate_init_method target_name, code
      end

      def == other
        self.class == other.class
      end

    private

      # Scan all the statements that do not belong to any particular class
      #   (meaning that they belong to Object) and add them to the Object class,
      #   which becomes the class from which all other classes will inherit from.
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
        code << "#include <stdbool.h>\n"
        @scope.include_files.each do |name|
          if name[0] == '<' && name[-1] == '>'
            code << "#include #{name}\n"
          else
            code << "#include \"#{name}\"\n"
          end
        end
        write_usability_macros code
        @statements.grep(Rubex::AST::TopStatement::Klass).each do |klass|
          declare_types code, klass.scope
        end
        write_user_klasses code
        write_function_declarations code
        code.nl
      end

      def write_user_klasses code
        code.nl
        @scope.ruby_class_entries.each do |klass|
          code << "VALUE #{klass.c_name};"
          code.nl
        end
      end

      def write_usability_macros code
        code.nl
        code.c_macro Rubex::RUBEX_PREFIX + "INT2BOOL(arg) (arg ? Qtrue : Qfalse)"
        code.nl
      end

      def write_function_declarations code
        @statements.each do |stmt|
          if stmt.is_a?(Rubex::AST::TopStatement::Klass)
            stmt.scope.ruby_method_entries.each do |entry|
              code.write_ruby_method_header(
                type: entry.type.type.to_s, c_name: entry.c_name)
              code.colon
            end

            stmt.scope.c_method_entries.each do |entry|
              if !entry.extern?
                code.write_c_method_header(
                  type: entry.type.type.to_s, 
                  c_name: entry.c_name, 
                  args: Helpers.create_arg_arrays(entry.type.arg_list))
                code.colon
              end
            end
          end
        end
      end

      def analyse_statement
        create_symtab_entries_for_top_statements
        @statements.each do |stat|
          stat.analyse_statement @scope
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
            if name != 'Object'
              ancestor_entry = @scope.find(stat.ancestor)
              if !ancestor_entry && Rubex::DEFAULT_CLASS_MAPPINGS[stat.ancestor]
                ancestor_c_name = Rubex::DEFAULT_CLASS_MAPPINGS[stat.ancestor]
                ancestor_scope = Rubex::SymbolTable::Scope::Klass.new(
                  stat.ancestor, nil)
                @scope.add_ruby_class(name: stat.ancestor, c_name: ancestor_c_name,
                  scope: ancestor_scope, ancestor: nil, extern: true)
              else
                ancestor_scope = ancestor_entry&.type&.scope || @scope
              end
              klass_scope = Rubex::SymbolTable::Scope::Klass.new(
                name, ancestor_scope)
            else
              ancestor_scope = @scope
              klass_scope = @scope
            end
            c_name = c_name_for_class name

            @scope.add_ruby_class(name: name, c_name: c_name, scope: klass_scope,
              ancestor: ancestor_scope, extern: false)
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
        code.write_func_declaration type: "void", c_name: name, args: [], static: false
        code.write_c_method_header type: "void", c_name: name, args: [], static: false
        code.block do
          @statements.each do |top_stmt|
            if top_stmt.is_a?(TopStatement::Klass) && top_stmt.name != 'Object'
              entry = @scope.find top_stmt.name
              code.declare_variable type: "VALUE", c_name: entry.c_name
            end
          end
          code.nl

          @statements.each do |top_stmt|
            # define a class
            if top_stmt.is_a?(TopStatement::Klass) && top_stmt.name != 'Object'
              entry = top_stmt.entry
              ancestor_entry = @scope.find top_stmt.ancestor.name
              c_name = ancestor_entry ? ancestor_entry.c_name : 'rb_cObject'
              rhs = "rb_define_class(\"#{entry.name}\", #{c_name})"
              code.init_variable lhs: entry.c_name, rhs: rhs
            end

            # specify allocation method in case of attached class
            if top_stmt.is_a?(TopStatement::AttachedKlass)
              entry = top_stmt.entry
              scope = top_stmt.scope
              alloc = ""
              alloc << "rb_define_alloc_func(#{entry.c_name}, "
              alloc << "#{scope.find(TopStatement::AttachedKlass::ALLOC_FUNC_NAME).c_name});\n"

              code << alloc
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
