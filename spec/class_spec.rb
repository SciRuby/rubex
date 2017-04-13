require 'spec_helper'

describe Rubex do
  test_case = 'class'
  path = "spec/fixtures/#{test_case}/#{test_case}"

  context "File: #{path}.rubex" do
    context ".ast" do
      it "generates the AST" do
        t = Rubex.ast(path + '.rubex')
        pp t
      end
    end

    context ".compile" do
      it "compiles to valid C file" do
        t,c,e = Rubex.compile((path + '.rubex'), true)
      end
    end
  end
end