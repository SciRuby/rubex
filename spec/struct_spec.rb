require 'spec_helper'
require 'pp'

describe Rubex do
  context "Rubex Ruby method with variable initialization and declaration" do
    before do
      @path = 'spec/fixtures/struct/struct'
    end

    context ".ast" do
      it "generates a valid AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C code" do
        t,c,e = Rubex.compile(@path + '.rubex', true)
        expect_compiled_code c, @path + ".c"
      end
    end
  end
end
