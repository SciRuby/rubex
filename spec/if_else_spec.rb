require 'spec_helper'

describe Rubex do
  test_case = "if_else"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile", focus: true do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile(@path + '.rubex', test: true)
        # expect_compiled_code(c, @path + ".c")
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          expect(adder_if_else(2, 3, 4)).to eq(4)
          expect(IfElseTest.new.ruby_obj_in_condition).to eq(20)

          pending("Multi line if statement conditions.") do
            expect(multi_line_if).to eq(true)
          end
        end
      end
    end
  end
end
