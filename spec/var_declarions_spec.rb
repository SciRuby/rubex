require 'spec_helper'

describe Rubex do
  context "Rubex Ruby method with variable initialization and declaration" do
    before do
      @path = 'spec/fixtures/basic_ruby_method/var_declarations.rubex'
    end

    compile ".ast" do
      it "generates a valid AST" do
        Rubex.ast
      end
    end

    context ".compile" do

    end
  end
end