module Rubex
  module AST
    module Node
      # Main class that acts as the apex node of the Rubex AST.
      class MainNode < Base
        include Rubex::Helpers::Writers
        attr_reader :statements
        
        # @param target_name [String] Target file name of the extension. The Init_
        #   method is named after this.
        # @param supervisor [Rubex::CodeSupervisor] Object for holding output code
        #   for header and implementation code of each rubex file.
        def process_statements(target_name, supervisor)
          @scope = Rubex::SymbolTable::Scope::Klass.new('Object', nil)
          add_top_statements_to_object_scope
          analyse_statement
          rescan_declarations @scope
          generate_header_file target_name, supervisor.header(target_name)
          
          code_writer = supervisor.code(target_name)
          code_writer << "#include \"#{target_name}.h\"\n"
          generate_code code_writer
          generate_init_method target_name, code_writer
        end
      end
    end
  end
end
