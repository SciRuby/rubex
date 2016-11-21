require 'spec_helper'

describe Rubex do
  context "basic Rubex Ruby callable method" do
    before do
      @path = 'spec/fixtures/basic_ruby_method.rubex'
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        Rubex.ast @path
      end
    end

    context ".compile" do
      it "generates valid C code" do
        Rubex.compile @path
      end
    end

    context ".extconf" do
      it "generates extconf for creating Makefile" do

      end
    end
  end
end