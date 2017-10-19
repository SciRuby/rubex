require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'bitwise_operators'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        t = Rubex::Compiler.ast @path + ".rubex"
      end
    end

    context ".compile" do
      it "generates valid C code" do
        t, c, e = Rubex::Compiler.compile @path + ".rubex", test: true
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          cls = BitWise.new
          expect(cls.wise_or).to eq(3)
          expect(cls.wise_and).to eq(1)
          expect(cls.wise_compli).to eq(-5)
          expect(cls.wise_xor).to eq(0)
          expect(cls.wise_lshift).to eq(6)
          expect(cls.wise_rshift).to eq(2)
        end
      end
    end
  end
end
