require 'spec_helper'
include Rubex::AST

describe Rubex do
  context "basic Rubex Ruby callable method" do
    before do
      @path = 'spec/fixtures/basic_ruby_method/'
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        arguments  = ArgumentList.new([
          CBaseType.new('i32', 'a'),
          CBaseType.new('i32', 'b')
        ])
        expr       = Expression::Binary.new('a', '+' ,'b')
        statement  = [Statement::Return.new(expr, "2")]
        method     = RubyMethodDef.new('addition', arguments, statement, "1")
        node       = Node.new([method])

        expect(Rubex.ast(@path + "basic_ruby_method.rubex")).to eq(node)
      end
    end

    context ".compile" do
      it "generates valid C code" do
        t, c, e = Rubex.compile @path + "basic_ruby_method.rubex", true
        expect(c.to_s).to eq(File.read(@path + "basic_ruby_method.c"))
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
