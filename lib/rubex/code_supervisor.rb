module Rubex
  # Class for storing Rubex files and their corresponding code writer objects.
  #   Each file has two code writers - header_writer and code_writer. The
  #   header_writer stores the file header of the outputted C code (the .h file)
  #   and the code_writer stores the actual implementation (the .c file).
  #
  # It is created only once in the execution of the compiler by the Compiler class.
  #   Data is stored in the @data class in the form:
  #   @data = {
  #     "file1.rubex" => {
  #       header: header_writer, # Rubex::CodeWriter instance.
  #       code:   code_writer, # Rubex:: CodeWriter instance.
  #     },
  #     "file2.rubex" => {
  #       header: header_writer, # Rubex::CodeWriter instance.
  #       code:   code_writer, # Rubex:: CodeWriter instance.
  #     }
  #   }
  class CodeSupervisor
    def initialize
      @data = {}
    end

    def init_file(file_name)
      header_writer = Rubex::CodeWriter.new(file_name, is_header: true)
      header_writer << "/*Header file for #{file_name}*/\n\n"

      code_writer = Rubex::CodeWriter.new(file_name)
      code_writer << "/*Code file for #{file_name}*/\n\n"
      
      @data[file_name] = {
        header: header_writer,
        code: code_writer
      }
    end

    def header(file_name)
      @data[file_name][:header]
    end

    def code(file_name)
      @data[file_name][:code]
    end
  end
end
