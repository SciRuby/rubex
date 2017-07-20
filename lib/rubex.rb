require 'rubex/error'
require 'rubex/helpers'
require 'rubex/code_writer'
require 'rubex/data_type'
require 'rubex/constants'
require 'rubex/ast'
require 'rubex/symbol_table'
require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile path, test: false, directory: nil
      tree = ast path, test: test
      target_name = extract_target_name path
      code = generate_code tree, target_name
      ext = extconf target_name, directory: directory
      
      return [tree, code, ext] if test
      write_files target_name, code, ext, directory: directory
    end

    def ast path, test: false
      begin
        parser = Rubex::Parser.new
        parser.parse(path)
        parser.do_parse
      rescue Racc::ParseError => e
        if test
          raise Racc::ParseError, e
        else
          error_msg = "PARSE ERROR:\n"
          error_msg << "Line: #{parser.string.split("\n")[parser.lineno]}\n"
          error_msg << "Location: #{parser.location}\n"
          error_msg << "Error:\n#{e}"
          STDERR.puts error_msg
        end
      end
    end

    def extconf target_name, directory: nil
      path = directory ? directory : "#{Dir.pwd}/#{target_name}"
      extconf = ""
      extconf << "require 'mkmf'\n"
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

    def write_files target_name, code, ext, directory: nil
      path = directory ? directory : "#{Dir.pwd}/#{target_name}"
      Dir.mkdir(path) unless directory
      
      code_file = File.new "#{path}/#{target_name}.c", "w+"
      code_file.puts code.to_s
      code_file.close

      extconf_file = File.new "#{path}/extconf.rb", "w+"
      extconf_file.puts ext
      extconf_file.close
    end
  end
end