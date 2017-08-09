module Rubex
  class CompilerConfig
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