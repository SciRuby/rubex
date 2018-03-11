require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'ruby_constant_scoping'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        t = Rubex::Compiler.ast @path + ".rubex"
      end
    end

    context ".compile" do
      it "generates valid C code" do
        t, c, e = Rubex::Compiler.compile @path + ".rubex", test: true
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          class Foo
            class Bar
              class Baz
                NUMBER = 10
              end
            end
          end
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          
          expect(get_eid.is_a?(Fixnum)).to eq(true)
          expect(user_chained_const).to eq(10)
        end
      end
    end
  end
end
