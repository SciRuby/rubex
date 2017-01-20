require 'spec_helper'

describe Rubex do
  context "Loops in Rubex" do
    before do
      @path = 'spec/fixtures/c_bindings/c_bindings.rubex'
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast @path
      end
    end

    context ".compile", focus: true do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile @path, true

        puts c
      end
    end
  end
end
