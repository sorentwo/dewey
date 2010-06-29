# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'dewey'
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Parker Selbert"]
  s.email       = ["parker@sorentwo.com"]
  s.homepage    = %q{http://github.com/sorentwo/dewey}
  s.summary     = "Google Docs fueled document conversion"
  s.description = "Dewey is a no-frills tool for utilizing Google Docs ability to convert documents between formats"

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "xmlsimple"

  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.md CHANGELOG.md TODO.md)
  s.require_path = 'lib'
end