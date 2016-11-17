require 'rubex/ast'
require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile file_name
      parser = Rubex::Parser.new
      parser.parse(file_name)
      a = parser.do_parse
      p a.inspect
    end

    def ast file_name
      
    end
  end
end