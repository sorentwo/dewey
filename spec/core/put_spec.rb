require 'spec_helper'

describe Dewey, '#put' do
  let(:bad) { sample_file 'bad_mimetype' }
  let(:psd) { sample_file 'sample_drawing.psd' }
  let(:spr) { sample_file 'sample_spreadsheet.xls' }
  let(:txt) { sample_file 'sample_document.txt' }

  before { stub_dewey_auth }

  it "raises when uploading unsupported file types" do
    lambda { Dewey.put(psd) }.should raise_exception(Dewey::DeweyError)
  end

  it "returns nil on a failed request" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL).to_return(:status => 300)

    Dewey.put(txt).should be_nil
  end

  it "get a resource id after putting a document" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL).
      to_return(:status => 201, :body => "<feed><entry><id>https://docs.google.com/feeds/id/document:12345</id></entry></feed>")

    Dewey.put(txt).should eq('document:12345')
  end

  it "get a resource id after putting a spreadsheet" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL).
      to_return(:status => 201, :body => "<feed><entry><id>https://docs.google.com/feeds/id/spreadsheet:12345</id></entry></feed>")

    Dewey.put(spr).should eq('spreadsheet:12345')
  end

  it "specifies an optional title in the header" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL)
    Dewey.put(txt, :title => 'Secret')

    a_request(:post, Dewey::GOOGLE_FEED_URL).
      with(:headers => { 'Slug' => 'Secret' }).should have_been_made
  end

  it "specifies the filesize in the header" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL)

    Dewey.put(txt)

    a_request(:post, Dewey::GOOGLE_FEED_URL).
      with(:headers => { 'Content-Length' => txt.size }).should have_been_made
  end
end

describe Dewey, '#put' do
  let(:txt) { sample_file 'sample_document.txt' }

  before { stub_dewey_auth }

  it "raises an error on a failed request" do
    stub_request(:post, Dewey::GOOGLE_FEED_URL).to_return(:status => 300)

    lambda { Dewey.put!(txt) }.should raise_exception(Dewey::DeweyError)
  end
end
