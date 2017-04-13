require 'spec_helper'

describe Rubex do
  context "Classes in Rubex" do
    before do
      @path = 'spec/fixtures/class/class'
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(@path + '.rubex')
        pp t
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile((@path + '.rubex'), true)

      end
    end
  end
end