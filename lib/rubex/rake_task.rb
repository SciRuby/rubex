require 'rake'
require 'rake/tasklib'
require "rake/extensiontask"
require_relative '../rubex.rb'

module Rubex
  class RakeTask < ::Rake::TaskLib

    def initialize name, gem_spec=nil
      @name = name
      @gem_spec = gem_spec
      @ext_dir = "ext/#{@name}"
      @lib_dir = 'lib'
      @source_pattern = "*.rubex"
      @compiled_pattern = "*.c"
      @config_script = "extconf.rb"
      define_compile_tasks
    end

    def define_compile_tasks
      namespace :rubex do
        desc "Compile a Rubex file into a shared object."
        task :compile do
          file_name = "#{Dir.pwd}/#{@ext_dir}/#{@name}#{@source_pattern[1..-1]}"
          Rubex::Compiler.compile file_name, directory: "#{@ext_dir}"
        end
      end
      Rake::ExtensionTask.new(@name)

      desc "Compile Rubex code into a .so file for use in Ruby scripts."
      task :compile => "rubex:compile"
    end
  end # class RakeTask
end # module Rubex