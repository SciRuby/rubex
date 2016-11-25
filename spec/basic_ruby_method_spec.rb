require 'spec_helper'

describe Rubex do
  context "basic Rubex Ruby callable method" do
    before do
      @path = 'spec/fixtures/basic_ruby_method/basic_ruby_method.rubex'
      include Rubex::AST
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        arguments  = ArgumentList.new
        arguments.push CBaseType.new('i32', 'b')
        arguments.push CBaseType.new('i32', 'a')
        method     = RubyMethodDef.new('addition', arguments)
        expr       = Expression::Addition.new 'a', 'b'
        statements = Statement::Return.new expr
        node       = Node.new method

        # TODO: Define == method on all nodes of AST.
        # expect(Rubex.ast(@path)).to eq(node)
      end
    end

    context ".compile" do
      it "generates valid C code" do
        Rubex.compile @path, true
      end
    end

    context ".extconf" do
      it "generates extconf for creating Makefile" do
        f = "require 'mkmf'\n"
        f << "create_makefile('basic_ruby_method/basic_ruby_method')\n"

        expect(Rubex.extconf("basic_ruby_method")).to eq(f)
      end
    end
  end
end