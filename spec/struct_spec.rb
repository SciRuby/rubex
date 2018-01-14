require 'spec_helper'

describe Rubex  do
  test_case = "struct"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates a valid AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C code" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"

          expect(structure("aa",2,3)).to eq(666)
          expect(struct_index).to eq(4)
          expect(access_struct_obj).to eq(1)
          expect(struct_ptr).to eq(7)
        end
      end
    end
  end
end
