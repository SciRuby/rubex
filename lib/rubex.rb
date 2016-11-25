require 'rubex/code_writer'
require 'rubex/data_type'
require 'rubex/constants'
require 'rubex/ast'
require 'rubex/symbol_table'
require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile path
      tree = ast path
      target_name = extract_target_name path
      code = Rubex::CodeWriter.new target_name

      generate_code tree, target_name, code
    end

    def ast path
      parser = Rubex::Parser.new
      parser.parse(path)
      parser.do_parse
    end

    def generate_code tree, target_name, code
      raise "Must be a Rubex::AST::Node, not #{tree.class}" unless 
        tree.is_a? Rubex::AST::Node

      tree.process_statements target_name, code
      # ap tree
      puts code.code
    end

    def extract_target_name path
      
    end
  end
end