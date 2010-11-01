# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'dewey/version'

Gem::Specification.new do |s|
  s.name        = 'dewey'
  s.version     = Dewey::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Parker Selbert"]
  s.email       = ["parker@sorentwo.com"]
  s.homepage    = %q{http://github.com/sorentwo/dewey}
  s.summary     = "Google Docs fueled document conversion"
  s.description = "Dewey is a no-frills tool for utilizing Google Docs ability to convert documents between formats"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "dewey"

  s.add_development_dependency "rspec"
  s.add_development_dependency "webmock"

  s.files        = Dir.glob("{lib}/**/*") + %w(README.md CHANGELOG.md)
  s.require_path = 'lib'
end
