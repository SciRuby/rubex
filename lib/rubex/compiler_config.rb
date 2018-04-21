module Rubex
  # Class for storing configuration of the compiler (gcc) that will compile
  #   the generated C code. This includes file names, compiler flags and other
  #   options required by Rubex.
  class CompilerConfig
    attr_accessor :debug
    
    def initialize
      @links = []
    end

    def add_link link_str
      @links << link_str
    end

    def link_flags
      @links.map { |l| l.dup.prepend('-l') }.join(' ')
    end

    def flush
      @links = []
    end
  end
end
