require 'rspec'
require 'awesome_print'
require 'pp'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubex'

def expect_compiled_code code, path
  expect(code.to_s).to eq(File.read(path))
end
