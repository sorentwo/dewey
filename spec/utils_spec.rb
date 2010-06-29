require 'spec_helper'

describe Dewey::Utils do
  # Partial spec borrowed from Rack::Utils spec
  it "should escape correctly" do
    Dewey::Utils.escape("fo<o>bar").should == "fo%3Co%3Ebar"
    Dewey::Utils.escape("a space").should == "a+space"
  end
end