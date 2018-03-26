require 'spec_helper'

describe Rubex do
  test_case = "box_op_multi_args"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing" do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          require 'numo/narray'
          n = Numo::DFloat.new(3,3).seq
          expect(multi_arg_box(n)).to eq(4.0)
        end
      end
    end
  end
end
