require 'spec_helper'

describe "Dewey.search" do
  before(:each) { stub_dewey_auth }

  it "can exactly match a single document" do
    stub_request(:get, "#{Dewey::GOOGLE_FEED_URL}?title=HR+Handbook&title-exact=true").
      to_return(:body => '<feed><id>https://docs.google.com/feeds/default/private/full</id><entry><id>document:12345</id></entry></feed>')
    
    Dewey.search('HR Handbook', :exact => true).should eq(['document:12345'])
  end

  it "can partially match a single document" do
    stub_request(:get, "#{Dewey::GOOGLE_FEED_URL}?title=Spec+101").
      to_return(:body => '<feed><entry><id>document:12345</id></entry></feed>')
    
    Dewey.search('Spec 101').should eq(['document:12345'])
  end
  
  it "can partially match multiple document" do
    stub_request(:get, "#{Dewey::GOOGLE_FEED_URL}?title=notes").
      to_return(:body => '<feed><entry><id>document:123</id></entry><entry><id>document:456</id></entry></feed>')
    
    Dewey.search('notes').should eq(['document:123', 'document:456'])
  end
end
