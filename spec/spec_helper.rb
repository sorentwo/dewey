require 'rubygems'
require 'rspec'
require 'webmock/rspec'

require File.dirname(__FILE__) + '/../lib/dewey'

RSpec.configure do |config|
  config.include WebMock::API
end

def sample_file(filename)
  File.new(File.join(File.dirname(__FILE__), 'mock_files', filename))
end
