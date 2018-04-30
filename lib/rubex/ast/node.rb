require 'rubex/helpers'
module Rubex
  module AST
    module Node
      class Base
        include Rubex::Helpers::Writers
        attr_reader :statements, :file_name
        
        def initialize(statements, file_name)
          @statements = statements.flatten
          @file_name = file_name
        end

        def ==(other)
          self.class == other.class
        end

        def analyse_statement
          create_symtab_entries_for_top_statements
          @statements.each do |stat|
            stat.analyse_statement @scope
          end
          @outside_statements.each do |stmt|
            stmt.analyse_statement @scope
          end
        end
        
        # Scan all the statements that do not belong to any particular class
        #   (meaning that they belong to Object) and add them to the Object class,
        #   which becomes the class from which all other classes will inherit from.
        #
        # Top-level statements that do not belong inside classes and which do not
        #   have any relevance inside a class at the level of a C extension are
        #   added to a different array and are analysed differently. For example
        #   'require' statements that are top level statements but cannot be 'defined'
        #   inside the Init_ method the way a ruby class or method can be. These are
        #   stored in @outside_statements.
        #
        # If the user defines multiple Object classes, they will share the same @scope
        #   object and will therefore have accessible members between each other. Since
        #   Ruby also allows users to open classes whenever and wherever they want, this
        #   behaviour is conformant with actual Ruby behaviour. It also implies that a
        #   FileNode can basically create an Object class of its own and the scope will
        #   shared between FileNode and MainNode and other FileNodes as long as the FileNode
        #   shares the same @scope object.
        def add_top_statements_to_object_scope
          temp = []
          combined_statements = []
          @outside_statements = []
          @statements.each do |stmt|
            if stmt.is_a?(TopStatement::Klass) || stmt.is_a?(TopStatement::CBindings)
              if !temp.empty?
                object_klass = TopStatement::Klass.new('Object', @scope, temp)
                combined_statements << object_klass
              end

              combined_statements << stmt
              temp = []
            elsif outside_statement?(stmt)
              @outside_statements << stmt
            elsif stmt.is_a?(Node::FileNode)
              combined_statements << stmt
            else
              temp << stmt
            end
          end

          unless temp.empty?
            combined_statements << TopStatement::Klass.new('Object', @scope, temp)
          end

          @statements = combined_statements
        end

        # TODO: accomodate all sorts of outside stmts like if blocks/while/for etc
        def outside_statement?(stmt)
          stmt.is_a?(Statement::Expression)
        end

        def generate_header_file(target_name, header)
          header_def_name = target_name.gsub("/", "_").gsub(".", "_").upcase + "_H"
          header << "#ifndef #{header_def_name}\n"
          header << "#define #{header_def_name}\n"
          header << "#include <ruby.h>\n"
          header << "#include <stdint.h>\n"
          header << "#include <stdbool.h>\n"
          header << "#include <math.h>\n"
          @scope.include_files.each do |name|
            header <<
              if name[0] == '<' && name[-1] == '>'
                "#include #{name}\n"
              else
                "#include \"#{name}\"\n"
              end
          end
          write_usability_macros header
          @statements.grep(Rubex::AST::TopStatement::Klass).each do |klass|
            declare_types header, klass.scope
          end
          write_user_klasses header
          write_global_variable_declarations header
          write_function_declarations header
          write_usability_functions header
          header << "#endif"
          header.nl
        end

        def write_global_variable_declarations(code)
          @statements.each do |stmt|
            next unless stmt.is_a?(TopStatement::Klass)
            stmt.statements.each do |s|
              next unless s.is_a?(TopStatement::MethodDef)
              s.scope.global_entries.each do |g|
                code << "static #{g.type} #{g.c_name};"
                code.nl
              end
            end
          end
        end

        def write_user_klasses(code)
          code.nl
          @scope.ruby_class_entries.each do |klass|
            unless Rubex::DEFAULT_CLASS_MAPPINGS.has_key?(klass.name)
              code << "VALUE #{klass.c_name};" 
              code.nl
            end
          end
        end

        def write_usability_macros(code)
          code.nl
          code.c_macro Rubex::RUBEX_PREFIX + 'INT2BOOL(arg) (arg ? Qtrue : Qfalse)'
          code.nl
        end

        def write_usability_functions(code)
          code.nl
          write_char_2_ruby_str code
        end

        def write_char_2_ruby_str(code)
          code << "VALUE #{Rubex::C_FUNC_CHAR2RUBYSTR}(char ch);"
          code.nl
          code << "VALUE #{Rubex::C_FUNC_CHAR2RUBYSTR}(char ch)"
          code.block do
            code << "char s[2];\n"
            code << "s[0] = ch;\n"
            code << "s[1] = '\\0';\n"
            code << "return rb_str_new2(s);\n"
          end
        end

        def write_function_declarations(code)
          @statements.each do |stmt|
            next unless stmt.is_a?(Rubex::AST::TopStatement::Klass)
            stmt.scope.ruby_method_entries.each do |entry|
              code.write_ruby_method_header(
                type: entry.type.type.to_s, c_name: entry.c_name
              )
              code.colon
            end

            stmt.scope.c_method_entries.each do |entry|
              next if entry.extern?
              code.write_c_method_header(
                type: entry.type.type.to_s,
                c_name: entry.c_name,
                args: Helpers.create_arg_arrays(entry.type.arg_list)
              )
              code.colon
            end
          end
        end

        def create_symtab_entries_for_top_statements
          @statements.each do |stat|
            next unless stat.is_a? Rubex::AST::TopStatement::Klass
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
                ancestor_scope = object_or_stdlib_klass_scope stat.ancestor
                @scope.add_ruby_class(name: stat.ancestor, c_name: ancestor_c_name,
                                      scope: @scope, ancestor: nil, extern: true)
              else
                ancestor_scope = ancestor_entry&.type&.scope || @scope
              end
              klass_scope = Rubex::SymbolTable::Scope::Klass.new(
                name, ancestor_scope
              )
            else
              ancestor_scope = @scope
              klass_scope = @scope
            end
            c_name = c_name_for_class name

            @scope.add_ruby_class(name: name, c_name: c_name, scope: klass_scope,
                                  ancestor: ancestor_scope, extern: false)
          end
        end

        def object_or_stdlib_klass_scope(name)
          name != 'Object' ? Rubex::SymbolTable::Scope::Klass.new(name, nil) :
            @scope
        end

        def c_name_for_class(name)
          c_name =
            if Rubex::DEFAULT_CLASS_MAPPINGS.key? name
              Rubex::DEFAULT_CLASS_MAPPINGS[name]
            else
              Rubex::RUBY_CLASS_PREFIX + name
            end

          c_name
        end

        def rescan_declarations(_scope)
          @statements.each do |stat|
            stat.respond_to?(:rescan_declarations) &&
              stat.rescan_declarations(@scope)
          end
        end

        # FIXME: Find a way to eradicate the if statement.
        def generate_code(supervisor)
          @statements.each do |stat|
            if stat.is_a?(Rubex::AST::Node::FileNode)
              stat.generate_code supervisor
            else
              stat.generate_code supervisor.code(@file_name)
            end
          end
        end

        def declare_c_variables_for_classes(code)
          @statements.each do |top_stmt|
            if top_stmt.is_a?(TopStatement::Klass) && top_stmt.name != 'Object'
              entry = @scope.find top_stmt.name
              code.declare_variable type: 'VALUE', c_name: entry.c_name
            end
          end
          code.nl        
        end

        def define_classes(code)
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
            next unless top_stmt.is_a?(TopStatement::AttachedKlass)
            entry = top_stmt.entry
            scope = top_stmt.scope
            alloc = ''
            alloc << "rb_define_alloc_func(#{entry.c_name}, "
            alloc << "#{scope.find(TopStatement::AttachedKlass::ALLOC_FUNC_NAME).c_name});\n"

            code << alloc
          end
          code.nl
        end

        def define_instance_and_singleton_methods_for_all_classes(code)
          @statements.each do |top_stmt|
            next unless top_stmt.is_a? TopStatement::Klass
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

        def write_outside_statements(code)
          @outside_statements.each do |stmt|
            stmt.generate_code(code, @scope)
          end
        end
        
        def generate_init_method(target_name, code)
          name = "Init_#{target_name}"
          code.new_line
          code.write_func_declaration type: 'void', c_name: name, args: [], static: false
          code.write_c_method_header type: 'void', c_name: name, args: [], static: false
          code.block do
            declare_c_variables_for_classes(code)
            write_outside_statements(code)
            define_classes(code)
            define_instance_and_singleton_methods_for_all_classes(code)
          end
        end
      end
    end
  end
end
