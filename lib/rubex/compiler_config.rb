module Rubex
  # Class for storing configuration of the compiler (gcc) that will compile
  #   the generated C code. This includes file names, compiler flags and other
  #   options required by Rubex.
  class CompilerConfig
    attr_accessor :debug, :srcs, :objs
    
    def initialize
      @links = []
      @srcs = []
      @objs = []
    end

    def add_link link_str
      @links << link_str
    end

    def link_flags
      @links.map { |l| l.dup.prepend('-l') }.join(' ')
    end

    def flush
      @links = []
      @srcs = []
      @objs = []
    end

    # add dependency on file so extconf will recognise it.
    def add_dep(file_name)
      @srcs << "#{file_name}.c"
      @objs << "#{file_name}.o"
    end
  end
end
