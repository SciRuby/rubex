require 'spec_helper'

describe Rubex do
  test_case = "error_handling"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile", focus: true do
      it "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black box testing", focus: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          cls = Handler.new

          expect(cls.error_test(1)).to eq(6)
          expect(cls.error_test(2)).to eq(7)
          expect(cls.error_test(3)).to eq(8)
          expect(cls.error_test(4)).to eq(9)

          expect {cls.test_uncaught_error}.to raise_error(ArgumentError)
          expect(cls.test_without_rescue).to eq(1)
          expect(cls.test_decl_inside_begin).to eq(44)
        end
      end
    end
  end
end
