require 'spec_helper'

describe Rubex do
  test_case = 'c_functions'

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

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          c = CFunctions.new
          expect(c.pure_ruby_method).to eq(50)
          expect { c.first_c_function(1,2) }.to raise_error(NoMethodError)

          expect(TypeCast.new.foo(5,5)).to eq(10)
        end
      end
    end
  end
end
