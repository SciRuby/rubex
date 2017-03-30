require 'spec_helper'

describe Rubex do
  path = "spec/fixtures/comments/comments"

	context "String literals. File: #{path}" do
    it "generate the AST." do
      t = Rubex.ast(path + '.rubex')
    end

    it "compiles to C." do
      t, c, e = Rubex.compile(path + '.rubex', true)
    end
  end
end