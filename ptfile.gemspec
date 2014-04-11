# encoding: utf-8

require File.expand_path('../lib/ptfile/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'ptfile'
  gem.date          = Time.now
  gem.version       = PTFile::VERSION

  gem.summary       = 'ProTracker modules reader and examiner'
  gem.description   = 'With this gem you can slice and dice ProTracker module files.'
  gem.license       = 'BSD'
  gem.authors       = ['Piotr S. Staszewski']
  gem.email         = 'p.staszewski@gmail.com'
  gem.homepage      = 'https://github.com/drbig/ptfile'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = gem.files.grep(%r{^spec/})
  gem.require_paths = ['lib']

  gem.add_dependency 'bindata', '~> 2.0'

  gem.add_development_dependency 'rspec', '~> 2.4'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.8'
end
