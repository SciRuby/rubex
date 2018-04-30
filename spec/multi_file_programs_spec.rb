require 'spec_helper'

describe Rubex do
  test_case = "multi_file_programs"

  context "Case: #{test_case}" do
    before do
      @dir = dir_str test_case
      @main_file = path_str test_case
      @file_names = ["a.rubex", "b.rubex", "multi_file_programs.rubex"]
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex::Compiler.ast(@main_file + '.rubex', source_dir: @dir)
      end
    end

    context ".compile", hell: true do
      it "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile(@main_file + '.rubex', files: @file_names,
                                        source_dir: @dir, test: true, multi_file: true)
      end
    end

    context "black box testing", hell: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_multiple_compiled_files(@main_file + '.rubex', @dir, @file_names) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          expect(C.new("hello ruby").bar).to eq("hello ruby")
          expect(D.new("ruby ").foo).to eq("ruby hello world")
        end
      end
    end
  end
end

