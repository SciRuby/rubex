require 'fileutils'
module Rubex
  class Compiler
    CONFIG = Rubex::CompilerConfig.new

    class << self
      def compile path, test: false, directory: nil, force: false, make: false
        tree = ast path, test: test
        target_name = extract_target_name path
        code = generate_code tree, target_name
        ext = extconf target_name, directory: directory
        CONFIG.flush

        return [tree, code, ext] if test
        write_files target_name, code, ext, directory: directory, force: force
        full_path = build_path(directory, target_name)
        load_extconf full_path
        run_make full_path if make
      end

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
