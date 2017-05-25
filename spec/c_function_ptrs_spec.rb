require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'c_function_ptrs'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        t = Rubex.ast @path + ".rubex"
      end
    end

    context ".compile", focus: true do
      it "generates valid C code" do
        t, c, e = Rubex.compile @path + ".rubex", test: true
        puts c
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          cls = CFunctionPtrs.new

          expect(cls.test_function_ptrs(true)) .to eq(5)
          expect(cls.test_function_ptrs(false)).to eq(7)
        end
      end
    end
  end
end
