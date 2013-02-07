# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "free_cite"
  gem.version       = "2.0.1"
  gem.authors       = ["David Judd", "FreeCite"]
  gem.email         = ["david@academia.edu"]
  gem.description   = %q{Parse citations}
  gem.homepage      = "http://github.com/academia-edu/free_cite"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'openurl'
  gem.add_dependency 'activesupport'
  gem.add_dependency 'crfpp'
  gem.add_dependency 'nokogiri'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'pry-debugger'
end
