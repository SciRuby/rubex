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

  Rubex::Compiler.compile(path + '.rubex', directory: dir)
  Dir.chdir(dir) do
    `ruby extconf.rb`
    `make`
  end
end

def delete_generated_files test_case, example=nil
  dir = dir_str test_case
  test_case = example if example
  Dir.chdir(dir) do
    FileUtils.rm Dir.glob("#{test_case}.{c,so,o,bundle}") + ["Makefile", "extconf.rb"]
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


def detect_os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      raise StandardError, "unknown os: #{host_os.inspect}"
    end
  )
end

def os_extension
  @extension_hash ||= {
    windows: 'dll',
    macosx: 'bundle',
    linux: 'so',
    unix: 'so'
  }
  @extension_hash[detect_os]
end
