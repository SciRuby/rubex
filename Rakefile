require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

$:.unshift File.expand_path("../lib", __FILE__)

Rake.application.rake_require "oedipus_lex"

desc "Generate Lexer"
task :lexer  => "lib/rubex/lexer.rex.rb"

desc "Generate Parser"
task :parser => :lexer do
  `racc -v -t lib/rubex/parser.racc -o lib/rubex/parser.racc.rb`
end

# -v -> verbose
# -t -> with debugging output

RSpec::Core::RakeTask.new(:spec)

task :spec => :parser
