require 'spec_helper'

describe Rubex do
  test_case = 'examples'

  examples = ['rcsv'].each do |example|
    context "Case: #{test_case}/#{example}" do
      before do
        @path = path_str test_case, example
      end

      context ".ast" do
        it "generates the AST" do
          t = Rubex.ast(@path + '.rubex')
        end
      end

      context ".compile", now: true do
        it "compiles to valid C file" do
          begin
            RubyProf.start
            t,c,e = Rubex.compile(@path + '.rubex', test: true)            
          rescue NoMemoryError => e
            res = RubyProf.stop
            printer = RubyProf::FlatPrinter.new(res)
            printer.print(STDOUT)            
          end


          puts c
        end
      end

      context "Black Box testing" do
        it "compiles and checks for valid output" do
          setup_and_teardown_compiled_files(test_case, example) do |dir|
            require_relative "#{dir}/#{example}.so"
          end
        end
      end
    end
  end
end