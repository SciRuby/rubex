require 'spec_helper'

describe Rubex do
  test_case = "c_bindings"

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
      it "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile((@path + '.rubex'), test: true)
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          expect(maths(3,5,"hello")).to be_within(0.001).of(300.763)
          expect(stray_cos).to be_within(0.001).of(-0.210)
          expect(A.new.ruby_cos).to be_within(0.001).of(-0.210)
          expect(RMath.new.ruby_sin(90)).to be_within(0.001).of(0.893)
        end
      end
    end
  end
end
