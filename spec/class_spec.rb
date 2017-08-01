require 'spec_helper'

describe Rubex do
  test_case = 'class'

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

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          k = Kustom.new
          expect(k.bye).to eq("Bye world!")

          k2 = Kustom2.new
          expect(k2.hello).to eq("This is a prelude.Hello world!")

          expect(Kustom2.ancestors[1]).to eq(Kustom)
        end
      end
    end
  end
end