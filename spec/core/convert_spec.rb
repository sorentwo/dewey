require 'spec_helper'

describe "Dewey.convert" do
  before(:each) do
    stub_dewey_auth

    @txt = sample_file 'sample_document.txt'
    @doc = sample_file 'sample_document.doc'
  end
  
  it "should put, get, and delete" do
    Dewey.should_receive(:put).with(@txt, 'sample').and_return('document:12345')
    Dewey.should_receive(:get).with('document:12345', :doc).and_return(@doc)
    Dewey.should_receive(:delete).with('document:12345').and_return(true)
    Dewey.convert(@txt, :title => 'sample', :format => :doc).should be(@doc)
  end
end
