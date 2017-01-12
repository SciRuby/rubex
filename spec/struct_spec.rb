require 'spec_helper'
require 'pp'

describe Rubex do
  context "Rubex Ruby method with variable initialization and declaration" do
    before do
      @path = 'spec/fixtures/struct/struct.rubex'
    end

    context ".ast", focus: true do
      it "generates a valid AST" do
        a = Rubex.ast @path

        pp t
      end
    end

    context ".compile" do
      it "compiles to valid C code" do
        t,c,e = Rubex.compile @path, true
      end
    end
  end
end
