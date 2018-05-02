require 'thor'
module Rubex
  # Cli for rubex using Thor(http://whatisthor.com/)
  class Cli < Thor
    
    desc 'generate FILE',
         'generates directory with name specified in the argument and creates an extconf.rb file which is required for C extensions'
    option :force, aliases: '-f', desc: 'replace existing files and directories'
    option :dir, aliases: '-d', desc: 'specify a directory for generating files', type: :string
    option :install, aliases: '-i',
           desc: 'automatically run install command after generating Makefile'
    option :debug, aliases: '-g', desc: 'enable debugging symbols when compiling with GCC'
    def generate(file)
      if (force = options[:force])
        directory = (options[:dir] ? options[:dir].to_s : Dir.pwd) +
                    "/#{Rubex::Compiler.extract_target_name(file)}"
        STDOUT.puts "Warning! you are about to replace contents in the directory '#{directory}', Are you sure? [Yn] "
        confirmation = STDIN.gets.chomp
        force = (confirmation == 'Y')
      end
      Rubex::Compiler.compile file, target_dir: options[:dir], force: force,
                              make: options[:install], debug: options[:debug]
    end

    desc 'install PATH',
         'run "make" utility to generate a shared object file required for C extensions'
    def install(path)
      Rubex::Compiler.run_make path
    end
  end
end
