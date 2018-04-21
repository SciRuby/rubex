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
      # TODO: change the directory: option to target_dir to make it more verbose.
      # TODO: The path can be relative to the source_dir if source_dir is specified.
      def compile path,
                  test: false,
                  directory: nil,
                  force: false,
                  make: false,
                  debug: false,
                  source_dir: nil,
                  files: nil
        tree = ast path, test: test
        target_name = extract_target_name path
        code = generate_code tree, target_name
        ext = extconf target_name, directory: directory
        CONFIG.flush
        CONFIG.debug = debug
        CONFIG.add_link "m" # link cmath libraries

        return [tree, code, ext] if test
        write_files target_name, code, ext, directory: directory, force: force
        full_path = build_path(directory, target_name)
        load_extconf full_path
        run_make full_path if make
      end

      # Generate the AST from Rubex source code. Do not use this function unless
      #   contributing to Rubex. Use CLI or rake tasks instead.
      #
      # @param path [String] Full path name of the rubex file.
      # @param test [Boolean] false Set to true if compiling rubex files for
      #   a test case.
      def ast path, test: false
        parser = Rubex::Parser.new
        parser.parse(path)
        parser.do_parse
      rescue Racc::ParseError => e
        raise e if test

        error_msg = "\nPARSE ERROR:\n"
        error_msg << "Line: #{parser.string.split("\n")[parser.lineno-1]}\n"
        error_msg << "Location: #{parser.location}\n"
        error_msg << "Error:\n#{e}"
        STDERR.puts error_msg
      end

      def extconf target_name, directory: nil
        path = build_path(directory, target_name)
        extconf = ""
        extconf << "require 'mkmf'\n"
        extconf << "$libs += \" #{CONFIG.link_flags}\"\n"
        extconf << "$CFLAGS += \" -g \"\n" if CONFIG.debug
        extconf << "create_makefile('#{path}/#{target_name}')\n"
        extconf
      end

      def generate_code tree, target_name
        code = Rubex::CodeWriter.new target_name
        raise "Must be a Rubex::AST::Node, not #{tree.class}" unless
          tree.is_a? Rubex::AST::Node
        tree.process_statements target_name, code
        code
      end

      def extract_target_name path
        File.basename(path).split('.')[0]
      end

      def write_files target_name, code, ext, directory: nil, force: false
        path = build_path(directory, target_name)
        FileUtils.rm_rf(path) if force && Dir.exist?(path)
        Dir.mkdir(path) unless Dir.exist?(path)

        code_file = File.new "#{path}/#{target_name}.c", "w+"
        code_file.puts code.to_s
        code_file.close

        extconf_file = File.new "#{path}/extconf.rb", "w+"
        extconf_file.puts ext
        extconf_file.close
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
    end
  end
end
