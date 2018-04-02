require 'spec_helper'

describe Rubex do
  test_case = "no_gil_compile_check"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "raises compile error" do
        expect {
          Rubex::Compiler.compile(@path + '.rubex', test: true)
        }.to raise_error(Rubex::CompileCheckError)
      end
    end
  end
end
