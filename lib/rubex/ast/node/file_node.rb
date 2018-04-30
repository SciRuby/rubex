module Rubex
  module AST
    module Node
      # Class for denoting a rubex file that is required from another rubex file.
      #   Takes the Object scope from the MainNode or other FileNode objects and
      #   uses that for storing any symbols that it encounters.
      class FileNode < Base
        def analyse_statement(object_scope)
          @scope = object_scope
          add_top_statements_to_object_scope
          super()
          rescan_declarations @scope
        end

        def generate_code(supervisor)
          supervisor.init_file(@file_name)
          code_writer = supervisor.code(@file_name)
          code_writer.write_include @file_name
          generate_header_file @file_name, supervisor.header(@file_name)
          super
          generate_init_method @file_name, code_writer
        end
      end
    end
  end
end
