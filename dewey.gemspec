# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'dewey/version'

Gem::Specification.new do |s|
  s.name        = 'dewey'
  s.version     = Dewey::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Parker Selbert']
  s.email       = ['parker@sorentwo.com']
  s.homepage    = %q{http://github.com/sorentwo/dewey}
  s.summary     = "Simple Google Docs library."
  s.description = "Light, simple Google Docs library for Ruby."

  s.rubyforge_project = 'dewey'

  s.add_development_dependency 'rake',    '~> 0.8.7'
  s.add_development_dependency 'rspec',   '~> 2.3.0'
  s.add_development_dependency 'webmock', '~> 1.4.0'
  s.add_development_dependency 'yard',    '~> 0.6.8'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
