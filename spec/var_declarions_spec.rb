require 'spec_helper'

describe Rubex do
  test_case = "var_declarations"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates a valid AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C code" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          expect(additive(1,5,2)).to be_within(0.001).of(6.6)
          expect(declare_in_the_middle).to eq(7)
          expect(obj_pointer).to eq([0,1,2])
        end
      end
    end
  end
end
