require 'spec_helper'

describe Rubex do
  test_case = 'ruby_constant_method_calls'

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile", now: true do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile(@path + '.rubex', test: true)
        puts c
      end
    end

    context "Black Box testing", now: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"

          expect(InitRubyClass.new.init_classes).to eq(
            [3,3, "Hello! This is a test", "converted."]
          )
        end
      end
    end
  end
end