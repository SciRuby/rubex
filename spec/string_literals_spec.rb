require 'spec_helper'

describe Rubex do
  test_case = "string_literals"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generate the AST." do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to C." do
        t, c, e = Rubex.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          expect(strings).to eq("Ted says \"Oh my God thats a big sandwich!\"")
          expect(string_ret).to eq("This is a returned string.")
        end
      end
    end
  end
end