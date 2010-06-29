require 'rubygems'
require 'spec'
# require 'artifice'

require File.dirname(__FILE__) + '/../lib/dewey'

def sample_file(filename)
  File.new(File.join(File.dirname(__FILE__), 'mock_files', filename))
end