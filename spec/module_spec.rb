require 'spec_helper'

describe Rubex do
  test_case = "module"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      skip "generates the AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      skip "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing" do
      skip "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          expect(Foo::Bar.new.baz).to eq("hello world")

          include Bar
          expect(b).to eq("b")

          include Outer::Inner
          expect(abc).to eq("abc")
        end
      end
    end
  end
end
