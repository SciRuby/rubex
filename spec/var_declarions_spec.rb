require 'spec_helper'

describe Rubex do
  context "Rubex Ruby method with variable initialization and declaration" do
    before do
      @path = 'spec/fixtures/var_declarations/var_declarations.rubex'
    end

    context ".ast" do
      it "generates a valid AST" do
        Rubex.ast @path
      end
    end

    context ".compile" do

    end
  end
end