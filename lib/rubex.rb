require 'rubex/error'
require 'rubex/code_writer'
require 'rubex/data_type'
require 'rubex/constants'
require 'rubex/ast'
require 'rubex/symbol_table'
require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile path, test=false
      tree = ast path
      target_name = extract_target_name path
      code = generate_code tree, target_name
      ext = extconf target_name
      
      return [tree, code, ext] if test
      write_files target_name, code, ext
    end

    def ast path
      parser = Rubex::Parser.new
      parser.parse(path)
      parser.do_parse
    end

    def extconf target_name, dir=nil
      extconf = ""
      extconf << "require 'mkmf'\n"
      extconf << "create_makefile('#{target_name}/#{target_name}')\n"
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

    def write_files target_name, code, ext
      Dir.mkdir(target_name)
      code_file = File.new "#{target_name}/#{target_name}.c", "w+"
      code_file.puts code.to_s
      code_file.close

      extconf_file = File.new "#{target_name}/extconf.rb", "w+"
      extconf_file.puts ext
      extconf_file.close
    end
  end
end