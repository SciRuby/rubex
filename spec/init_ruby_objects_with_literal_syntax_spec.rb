require 'spec_helper'

describe Rubex do
  test_case = "init_ruby_objects_with_literal_syntax"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates a valid AST" do
        t = Rubex.ast(@path + '.rubex')
      end
    end

    context ".compile", now: true do
      it "compiles to valid C code" do
        t,c,e = Rubex.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing", focus: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.so"
          array = [1,2,3,4,5,6]
          string = "Hello world! Lets have a picnic!"
          h = {
            "hello" => array,
            "world" => 666,
            "message" => string
          }
          expect(DataInit.new.init_this(1,2,2)).to eq(h)
        end
      end
    end
  end
end
