require 'spec_helper'

describe Rubex do
  pending("implement recursion") do
    test_case = "recursion"

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

            expect(Fibonnaci.new.compute(5)).to eq(5)
          end
        end
      end
    end
  end
end
