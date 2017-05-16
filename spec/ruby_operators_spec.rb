require 'spec_helper'

describe Rubex do
  test_case = "ruby_operators"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile(@path + '.rubex', test: true)
      end
    end

    context "Black box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          expect(StringCaller.new.call_now("foo!")).to eq("f")

          cls = BinaryOperators.new
          expect(cls.lt("aa", "bb")).to eq(true)
          expect(cls.lt("abc","abc")).to eq(false)

          expect(cls.double_eq([1,2,3,4],[1,2,3,4])).to eq(true)
          expect(cls.double_eq("foo", "bar")).to eq(false)
        end
      end
    end
  end
end
