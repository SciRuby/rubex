require 'spec_helper'

describe Rubex do
  path = "spec/fixtures/binding_ptr_args/binding_ptr_args"

	context "Pointer dtypes in C bindings. File: #{path}", focus: true do
    it "generates the AST." do
      t = Rubex.ast(path + '.rubex')
    end

    it "compiles to C." do
      t, c, e = Rubex.compile(path + '.rubex', true)
    end
  end
end