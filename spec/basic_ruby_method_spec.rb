require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'basic_ruby_method'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        t = Rubex::Compiler.ast @path + ".rubex"
      end
    end

    context ".compile", tit: true do
      it "generates valid C code" do
        t, c, e, h = Rubex::Compiler.compile @path + ".rubex", test: true
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do
          dir = dir_str test_case
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          expect(addition(4,5)).to eq(9)
        end
      end
    end
  end
end
