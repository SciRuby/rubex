require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'typecasting'

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
      end
    end

    context "Black Box testing", focus: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do
          dir = dir_str test_case
          require_relative "#{dir}/#{test_case}.so"
          
          t = TestTypeCasts.new

          expect(t.test_this).to eq(10)
        end
      end
    end
  end
end
