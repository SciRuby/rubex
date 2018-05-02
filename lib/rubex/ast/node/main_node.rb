module Rubex
  module AST
    module Node
      # Main class that acts as the apex node of the Rubex AST.
      class MainNode < Base

        # Central method that starts that processing of the AST. Called by Compiler.
        #
        # @param target_name [String] Target file name of the extension. The Init_
        #   method is named after this.
        # @param supervisor [Rubex::CodeSupervisor] Object for holding output code
        #   for header and implementation code of each rubex file.
        def process_statements(target_name, supervisor)
          if target_name != @file_name
            raise Rubex::TargetFileMismatchError,
                  "target_name #{target_name} does not match @file_name #{@file_name}"
          end
          @scope = Rubex::SymbolTable::Scope::Klass.new('Object', nil)
          add_top_statements_to_object_scope
          create_symtab_entries_for_top_statements(@scope)
          analyse_statement
          rescan_declarations @scope
          generate_common_utils_files supervisor
          generate_header_and_implementation supervisor
        end

        def generate_common_utils_files supervisor
          supervisor.init_file(Rubex::COMMON_UTILS_FILE)
          header = supervisor.header(Rubex::COMMON_UTILS_FILE)
          header.in_header_guard(Rubex::COMMON_UTILS_CONST) do
            header << "#include <ruby.h>\n"
            header << "#include <stdint.h>\n"
            header << "#include <stdbool.h>\n"
            header << "#include <math.h>\n"
            write_usability_functions_header header
            write_usability_macros header
          end

          code = supervisor.code(Rubex::COMMON_UTILS_FILE)
          code.write_include(Rubex::COMMON_UTILS_FILE)
          write_usability_functions_code code

          Rubex::Compiler::CONFIG.add_dep(Rubex::COMMON_UTILS_FILE)
        end

        def generate_header_and_implementation(supervisor)
          generate_header_file @file_name, supervisor.header(@file_name)
          code_writer = supervisor.code(@file_name)
          code_writer.write_include @file_name
          generate_code supervisor
          generate_init_method code_writer
        end
      end
    end
  end
end
