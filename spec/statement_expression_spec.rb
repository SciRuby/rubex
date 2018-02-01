require 'spec_helper'

describe Rubex do
  test_case = "statement_expression"

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
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          def foo; end
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          expect(expr_stat).to eq("success.")
        end
      end
    end
  end
end
