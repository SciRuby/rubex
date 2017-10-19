# coding: utf-8
$:.unshift File.expand_path("../lib", __FILE__)

require 'rcsv/version.rb'

Rcsv::DESCRIPTION = <<MSG
A Crystal-inspired language for writing Ruby extensions
MSG

Gem::Specification.new do |spec|
  spec.name          = 'rcsv'
  spec.version       = Rcsv::VERSION
  spec.authors       = ['Sameer Deshmukh']
  spec.email         = ['sameer.deshmukh93@gmail.com']
  spec.summary       = Rcsv::DESCRIPTION
  spec.description   = Rcsv::DESCRIPTION
  spec.license       = 'BSD-2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'rubex', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'rspec'
end
