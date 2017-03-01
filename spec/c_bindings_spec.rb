require 'spec_helper'

describe Rubex do
  context "Loops in Rubex" do
    before do
      @path = 'spec/fixtures/c_bindings/c_bindings'
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile((@path + '.rubex'), true)
        expect_compiled_code c, @path + ".c"
      end
    end
  end
end
