require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'cli'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
      @dir = dir_str test_case
      @cli = Rubex::Cli.new
    end

    context 'generate' do
      it "is expected to create valid files for generating Makefile in current Directory" do
        @cli.generate("#{@path}.rubex")
        expect(File.exist?("#{test_case}/#{test_case}.c")).to be(true)
        expect(File.exist?("#{test_case}/extconf.rb")).to be(true)
        FileUtils.rm_rf("#{Dir.pwd}/cli")
      end

      it "is expected to create valid files for generating Makefile in specified directory" do
        setup_and_teardown_compiled_files(test_case) do
          @cli.options = {dir: @dir}
          @cli.generate("#{@path}.rubex")
          expect(File.exist?("#{@path}.c")).to be(true)
          expect(File.exist?("#{@dir}/extconf.rb")).to be(true)
        end
      end
    end

    context 'install' do
      it "is expected to run make utility and create a valid .#{os_extension} file" do
        setup_and_teardown_compiled_files(test_case) do
          @cli.options = {dir: @dir}
          @cli.generate("#{@path}.rubex")
          @cli.install(@dir)
          expect(File.exist?("#{@path}.#{os_extension}")).to be(true)
        end
      end
    end
  end
end
