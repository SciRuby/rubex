require 'spec_helper'

describe Rubex do
  test_case = "var_declarations"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates a valid AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C code" do
        t,c,e = Rubex.compile(@path + '.rubex', test: true)
        # expect_compiled_code c, path + ".c"
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          expect(additive(1,5,2)).to be_within(0.001).of(6.6)
        end
      end
    end
  end
end
