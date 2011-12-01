require 'spec_helper'

describe "Dewey.convert" do
  let(:txt) { sample_file 'sample_document.txt' }
  let(:doc) { sample_file 'sample_document.doc' }

  before do
    stub_dewey_auth
  end

  it "should put, get, and delete" do
    # Put
    stub_request(:post, Dewey::GOOGLE_FEED_URL).
      to_return(:status => 201, :body => "<feed><entry><id>https://docs.google.com/feeds/id/document:12345</id></entry></feed>")

    # Get
    stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?id=12345&exportFormat=doc&format=doc").
      to_return(:body => doc)

    # Delete
    stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true")

    returned = Dewey.convert(txt, :title => 'sample', :format => :doc)

    returned.should be_instance_of(File)
    returned.path.should match(/\.doc/)
  end
end
