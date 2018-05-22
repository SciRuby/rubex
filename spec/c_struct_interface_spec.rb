require 'spec_helper'
include Rubex::AST

describe Rubex do
  test_case = 'c_struct_interface'

  context "Case : #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "returns a valid Abstract Syntax Tree" do
        t = Rubex::Compiler.ast @path + ".rubex"
      end
    end

    context ".compile", hell: true do
      it "generates valid C code" do
        t, c, e, h = Rubex::Compiler.compile @path + ".rubex", test: true
      end
    end

    context "Black Box testing", hell: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          id = 44
          m = Music.new("Animals as Leaders", "CAFO", id)

          expect(m.artist).to eq("Animals as Leaders")
          expect(m.title) .to eq("CAFO")
          expect(m.id)    .to eq(id)
          expect(m.id_i)  .to eq(id + 1)

          t = A.new

          expect(t.foo).to eq(55)
        end
      end
    end
  end
end
