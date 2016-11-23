require 'spec_helper'

describe Rubex do
  context "basic Rubex Ruby callable method" do
    before do
      @path = 'spec/fixtures/basic_ruby_method.rubex'
      include Rubex::AST
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        # arguments = ArgumentList.new
        # arguments.push CBaseType.new 'i32', 'a'
        # arguments.push CBaseType.new 'i32', 'b'
        # method = MethodDef.new('addition', arguments)
        # expr = Expression::Addition.new 'a', 'b'
        # statements = Statement::Return.new expr
        p = Rubex.ast @path
        ap p.inspect
      end
    end

    context ".compile" do
      it "generates valid C code" do
        # Rubex.compile @path
      end
    end

    context ".extconf" do
      it "generates extconf for creating Makefile" do

      end
    end
  end
end