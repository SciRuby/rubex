require 'spec_helper'

describe Rubex do
  path = "spec/fixtures/string_literals/string_literals"

  context "String literals. File: #{path}" do
    it "generate the AST." do
      t = Rubex.ast(path + '.rubex')
      pp t
    end

    it "compiles to C.", focus: true do
      t, c, e = Rubex.compile(path + '.rubex', true)
      puts t
      puts c
    end
  end
end