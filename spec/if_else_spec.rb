require 'spec_helper'

describe Rubex do
  context "Rubex method with if-elsif-else blocks" do
    before do
      @path = 'spec/fixtures/expressions/if_else.rubex'
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast @path

        pp t
      end
    end
    context ".compile" do
      it "compiles to valid C file" do
        # Rubex.compile @path
      end
    end
  end
end