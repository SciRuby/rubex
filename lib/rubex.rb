require 'rubex/parser.racc.rb'

module Rubex
  class << self
    def compile file_name
      parser = Rubex::Parser.new
      parser.prepare(file_name).do_parse
    end
  end
end