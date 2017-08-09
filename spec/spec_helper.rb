require 'rspec'
require 'awesome_print'
require 'pp'
require 'pry'
require 'pretty_backtrace'
require 'ruby-prof'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

# PrettyBacktrace.enable

require 'rubex'

def dir_str test_case
  "#{Dir.pwd}/spec/fixtures/#{test_case}"
end

def path_str test_case, example=nil
  example = test_case if example.nil?
  "#{Dir.pwd}/spec/fixtures/#{test_case}/#{example}"
end

def generate_shared_object test_case, example=nil
  path = path_str test_case, example
  dir = dir_str test_case

  Rubex.compile(path + '.rubex', directory: dir)
  Dir.chdir(dir) do
    `ruby extconf.rb`
    `make`
  end
end

def delete_generated_files test_case, example=nil
  dir = dir_str test_case
  test_case = example if example
  Dir.chdir(dir) do
    [
      "#{test_case}.c", "#{test_case}.so", "Makefile",
      "extconf.rb"    , "#{test_case}.o"
    ].each do |f|
      FileUtils.rm f
    end
  end
end

def setup_and_teardown_compiled_files test_case, example=nil, &block
  generate_shared_object test_case, example
  dir = dir_str test_case
  begin
    block.call(dir)
  ensure
    delete_generated_files test_case, example
  end
end

def expect_compiled_code code, path
  expect(code.to_s).to eq(File.read(path))
end
