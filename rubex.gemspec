# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'rubex/version.rb'

Rubex::DESCRIPTION = <<MSG
A Ruby-like language for writing Ruby C extensions.

Rubex keeps you happy even when writing C extensions.
MSG

Gem::Specification.new do |spec|
  spec.name          = 'rubex'
  spec.version       = Rubex::VERSION
  spec.authors       = ['Sameer Deshmukh']
  spec.email         = ['sameer.deshmukh93@gmail.com']
  spec.summary       = Rubex::DESCRIPTION
  spec.description   = Rubex::DESCRIPTION
  spec.homepage      = "http://github.com/v0dro/rubex"
  spec.license       = 'BSD-2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'racc', '~> 1.4.14'
  spec.add_runtime_dependency 'rake-compiler', '~> 1.0.4'

  spec.add_development_dependency 'oedipus_lex', '~> 2.4'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pretty_backtrace'
  spec.add_development_dependency 'ruby-prof'
end
