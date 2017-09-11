require 'thor'
module Rubex
  # Cli for rubex using Thor(http://whatisthor.com/)
  class Cli < Thor
    desc 'generate FILE', 'generates directory with name specified in the argument and creates an extconf.rb file which is required for C extensions'
    option :force, aliases: '-f', desc: 'replace existing files and directories'
    option :dir, aliases: '-d', desc: 'specify a directory for generating files'
    def generate(file)
      Rubex::Compiler.compile file, force: options[:force], directory: options[:dir]
    end

  end
end
