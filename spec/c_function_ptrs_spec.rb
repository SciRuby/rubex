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

    context ".compile", now: true do
      it "generates valid C code" do
        t, c, e = Rubex.compile @path + ".rubex", test: true
      end
    end

    context "Black Box testing", now: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          cls = CFunctionPtrs.new

          expect(cls.test_c_function_pointers(true)) .to eq(5)
          expect(cls.test_c_function_pointers(false)).to eq(7)
          expect(cls.test_pass_by_name).to eq(5)
        end
      end
    end
  end
end
