require 'spec_helper'

describe "Dewey.delete" do
  before(:each) { stub_dewey_auth }

  it "deletes a resource from an id" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true")
    Dewey.delete('document:12345').should be_true
  end

  it "deletes a resource from a title" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true")
    Dewey.should_receive(:search).with('My Document', { :exact => true }).and_return(['document:12345'])

    Dewey.delete('My Document').should be_true
  end

  it "uses If-Match in the header to ignore external modifications" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true")
    Dewey.delete('document:12345')

    a_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").
      with(:headers => { 'If-Match' => '*' }).should have_been_made
  end

  it "reports false when a resource can't be found by id" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").to_return(:status => 300)
    Dewey.delete('document:12345').should be_false
  end

  it "reports false when a resource can't be found by title" do
    Dewey.should_receive(:search).with('Not My Document', { :exact => true }).and_return([])

    Dewey.delete('Not My Document').should be_false
  end

  it "doesn't delete with the trash option" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345")
    Dewey.delete('document:12345', :trash => true).should be_true
  end
end

describe "Dewey.delete!" do
  before(:each) { stub_dewey_auth }

  it "raises an error when a resource can't be found" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").to_return(:status => 300)
    lambda { Dewey.delete!('document:12345') }.should raise_exception(Dewey::DeweyError)
  end

  it "doesn't delete with the trash option" do
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345")
    Dewey.delete!('document:12345', :trash => true).should be_true
  end
end
