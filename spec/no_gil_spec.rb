require 'spec_helper'

describe Rubex do
  test_case = "no_gil"

  context "Case: #{test_case}" do
    before do
      @path = path_str test_case
    end

    context ".ast" do
      it "generates the AST" do
        t = Rubex::Compiler.ast(@path + '.rubex')
      end
    end

    context ".compile", hell: true do
      it "compiles to valid C file" do
        t,c,e = Rubex::Compiler.compile(@path + '.rubex', test: true)
      end
    end

    context "Black Box testing", hell: true do
      it "compiles and checks for valid output" do
        setup_and_teardown_compiled_files(test_case) do |dir|
          require_relative "#{dir}/#{test_case}.#{os_extension}"
          
          N = 9999          
          n = Thread.new { work_without_gil(N) }
          n = Thread.new { work_without_gil(N) }
          n.join; n.join
        end
      end
    end
  end
end
