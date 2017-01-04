require 'spec_helper'

describe Rubex do
  context "Loops in Rubex" do
    before do
      @path = 'spec/fixtures/ruby_strings/ruby_strings.rubex'
    end

    context ".ast" do
      it "generates the AST", focus: true do
        t = Rubex.ast @path

        pp t
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile @path, true
        # pp t
        # puts c
      end
    end
  end
end
