require 'fileutils'
module Rubex
  class Compiler
    CONFIG = Rubex::CompilerConfig.new

    class << self
      # Compile the Rubex file(s) into .c file(s). Do not use this function directly
      #   unless you're contributing to Rubex. Use the Rake tasks or command line
      #   interface instead.
      #
      # @param path [String] Full path to file. Main file in case of multiple
      #   file compilation.
      # @param test [Boolean] false Set to true if compiling rubex files for
      #   a test case.
      # @param multi_file [Boolean] false If true, return the CodeSupervisor
      #   object for code analysis by user. Applicable only if test: opt is true.
      # @param directory [String] nil Directory where the compiled rubex files
      #   should be placed.
      # @param force [Boolean] false If set to true, will forcefully overwrite
      #    any .c files that were previously generated.
      # @param make [Boolean] false If true, will automatically generate the .so
      #    file from compiled C binaries.
      # @param debug [Boolean] false If true, will compile C programs with gcc
      #    using the -g option.
      # @param source_dir [String] nil String specifying the source directory
      #    inside which the source Rubex files will be placed in case of multi-file
      #    programs.
      # @param files [Array[String]] nil An Array specifying the file names to
      #   compile w.r.t the source_dir directory.
      #
      # TODO: The path can be relative to the source_dir if source_dir is specified.
      def compile path,
                  test: false,
                  multi_file: false,
                  target_dir: nil,
                  force: false,
                  make: false,
                  debug: false,
                  source_dir: nil,
                  files: nil
        tree = ast path, source_dir: source_dir, test: test
        target_name = extract_target_name path
        supervisor = generate_code tree, target_name
        ext = extconf target_name, target_dir: target_dir
        CONFIG.flush
        CONFIG.debug = debug
        CONFIG.add_link "m" # link cmath libraries

        if test && !multi_file
          return [tree, supervisor.code(target_name), ext,
                  supervisor.header(target_name)]
        elsif test && multi_file
          return [tree, supervisor, ext]
        end
        write_files target_name, supervisor, ext, target_dir: target_dir, force: force
        full_path = build_path(target_dir, target_name)
        load_extconf full_path
        run_make full_path if make
      end

      # Generate the AST from Rubex source code. Do not use this function unless
      #   contributing to Rubex. Use CLI or rake tasks instead.
      #
      # @param path [String] Full path name of the rubex file.
      # @param test [Boolean] false Set to true if compiling rubex files for
      #   a test case.
      # @param source_dir [String] nil Path of the directory that contains the
      #   source files.
      def ast path, test: false, source_dir: nil
        parser = Rubex::Parser.new
        parser.parse(path, source_dir, false)
        parser.do_parse
      rescue Racc::ParseError => e
        raise e if test

        error_msg = "\nPARSE ERROR:\n"
        error_msg << "Line: #{parser.string.split("\n")[parser.lineno-1]}\n"
        error_msg << "Location: #{parser.location}\n"
        error_msg << "Error:\n#{e}"
        STDERR.puts error_msg
      end

      def extconf target_name, target_dir: nil
        path = build_path(target_dir, target_name)
        extconf = ""
        extconf << "require 'mkmf'\n"
        extconf << "$libs += \" #{CONFIG.link_flags}\"\n"
        extconf << "$CFLAGS += \" -g \"\n" if CONFIG.debug
        extconf << "create_makefile('#{path}/#{target_name}')\n"
        extconf
      end

      def generate_code tree, target_name
        supervisor = Rubex::CodeSupervisor.new
        supervisor.init_file(target_name)
        raise "Must be a Rubex::AST::Node::MainNode, not #{tree.class}" unless
          tree.is_a? Rubex::AST::Node::MainNode
        tree.process_statements target_name, supervisor
        supervisor
      end

      def extract_target_name path
        File.basename(path).split('.')[0]
      end

      # Write .c and .h files from the generated C code from rubex files.
      #
      # @param target_name [String] Target name of the root file.
      # @param supervisor [Rubex::CodeSupervisor] Container for code.
      # @param ext [String] A String representing the extconf file.
      # @param directory [String] nil Target directory in which files are to be placed.
      # @param force [Boolean] false Recreate the target directory and rewrite the
      #   files whether they are already present or not.
      def write_files target_name, supervisor, ext, target_dir: nil, force: false
        path = build_path(target_dir, target_name)
        FileUtils.rm_rf(path) if force && Dir.exist?(path)
        Dir.mkdir(path) unless Dir.exist?(path)

        supervisor.files.each do |file|
          write_to_file "#{path}/#{file}.c", supervisor.code(target_name).to_s
          write_to_file "#{path}/#{file}.h", supervisor.header(target_name).to_s
        end
        
        write_to_file "#{path}/extconf.rb", ext
      end

      def load_extconf path
        Dir.chdir(path) do
          system("ruby #{path}/extconf.rb")
        end
      end

      def run_make path
        Dir.chdir(path) do
          system("make -C #{path}")
        end
      end

      def build_path directory, target_name
        directory = (directory ? directory.to_s : Dir.pwd)
       unless directory.end_with?(target_name)
          directory += "/#{target_name}"
       end
        directory
      end
      
      private

      def write_to_file path, contents
        f = File.new path, "w+"
        f.puts contents
        f.close
      end
    end
  end
end
