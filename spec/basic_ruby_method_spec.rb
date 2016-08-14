require 'spec_helper'

describe Rubex do
  context ".compile" do
    it "compiles a basic Ruby callable method to C" do
      Rubex.compile 'spec/fixtures/basic_ruby_method.rubex'
    end
  end
end