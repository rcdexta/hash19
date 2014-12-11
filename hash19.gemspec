# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hash19/version'

Gem::Specification.new do |spec|
  spec.name          = 'hash19'
  spec.version       = Hash19::VERSION
  spec.authors       = ['RC']
  spec.email         = ['rc.chandru@gmail.com']
  spec.summary       = %q{Hash helpers to map complex JSON to ruby objects}
  spec.description   = %q{Handles associations and eager loading and collection injection }
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'

  spec.add_runtime_dependency 'jsonpath', '~> 0.5.6'
  spec.add_runtime_dependency 'eldritch'

end
