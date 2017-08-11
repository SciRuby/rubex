require 'spec_helper'

describe Rubex do
  test_case = "ruby_raise"

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
          require_relative "#{dir}/#{test_case}.so"

          cls = RaiseTester.new
          expect { cls.test_raise(true) }.to raise_error(ArgumentError)
          expect { cls.test_raise(nil) }.to raise_error(NoMethodError)
        end
      end
    end
  end
end
