require 'rake'
require 'rake/tasklib'
require "rake/extensiontask"
require_relative '../rubex.rb'

module Rubex
  class RakeTask < ::Rake::TaskLib
    attr_reader :ext_dir, :rubex_files
    attr_accessor :debug

    def initialize name, gem_spec=nil, &block
      @name = name
      @gem_spec = gem_spec
      @ext_dir = "#{Dir.pwd}/ext/#{@name}"
      @lib_dir = 'lib'
      @source_pattern = "*.rubex"
      @compiled_pattern = "*.c"
      @config_script = "extconf.rb"
      @debug = true
      instance_eval(&block) if block_given?
      define_compile_tasks
    end

    # Change the directory that contains rubex files. Overrides default
    # assumption of gem file structure.
    #
    # @param [String] ext_dir Path to new ext dir.
    def ext ext_dir
      @ext_dir = ext_dir
    end

    # Specify the names of Rubex files with respect to ext directory if compiling
    # multiple files.
    #
    # @param [Array[String]] files Array containing names of all files relative to
    #   ext directory as Strings.
    def files files
      @rubex_files = files
    end

    def define_compile_tasks
      namespace :rubex do
        desc "Compile a Rubex file into a shared object."
        task :compile do
          file_name = "#{@ext_dir}/#{@name}#{@source_pattern[1..-1]}"
          Rubex::Compiler.compile file_name, target_dir: "#{@ext_dir}", debug: @debug
        end

        desc "Delete all generated files."
        task :clobber do
          path = @ext_dir
          unless path.end_with?(@name)
            path += "/#{@name}"
          end

          Dir.chdir(path) do
            FileUtils.rm(
              Dir.glob(
              "#{path}/*.{c,h,so,o,bundle,dll}") + ["Makefile", "extconf.rb"], force: true
            )
          end
        end
      end
      Rake::ExtensionTask.new(@name)

      desc "Compile Rubex code into a .so file for use in Ruby scripts."
      task "compile" => "rubex:compile"
    end
  end # class RakeTask
end # module Rubex
