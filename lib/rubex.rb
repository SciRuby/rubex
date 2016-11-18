require 'rubex/ast'
require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile file_name
      parser = Rubex::Parser.new
      parser.parse(file_name)
      p parser.do_parse.inspect
    end

    def ast file_name
      parser = Rubex::Parser.new
      parser.parse(file_name)
      parser.do_parse
    end
  end
end