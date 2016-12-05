require 'spec_helper'

describe Rubex do
  context "Rubex method with arithmetic expressions" do
    before do
      @path = 'spec/fixtures/expressions/expressions.rubex'
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast @path
      end
    end
    context ".compile" do
      it "compiles to valid C file" do
        c, e = Rubex.compile @path, true
      end
    end
  end
end