require 'spec_helper'

describe "Dewey.get" do 
  before(:each) { stub_dewey_auth }

  it "raises with an invalid format" do
    lambda { Dewey.get('document:12345', :format => :psd) }.should raise_exception(Dewey::DeweyError)
  end

  it "returns a tempfile" do
    stub_request(:get, /.*/).to_return(:body => sample_file('sample_document.txt'))

    Dewey.get('document:12345').should be_kind_of(Tempfile)
  end

  it "returns the tempfile at position 0" do
    stub_request(:get, /.*/).to_return(:body => sample_file('sample_document.txt'))
    
    Dewey.get('document:12345').read.should eq(sample_file('sample_document.txt').read)
  end

  it "downloads a document by id" do
    stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345").
      to_return(:body => sample_file('sample_document.txt'))
    
    Dewey.get('document:12345').should_not be_nil
  end
  
  it "sets the export format when format is provided" do
    stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345&exportFormat=doc&format=doc").
      to_return(:body => sample_file('sample_document.doc'))
    
    Dewey.get('document:12345', :format => :doc).should_not be_nil
  end

  it "returns nil when the id can't be found" do
    stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345").
      to_return(:status => 301)

    Dewey.get('document:12345').should be_nil
  end

  it "downloads a document by title" do
    Dewey.should_receive(:search).with('My Document', { :exact => true }).and_return(['document:12345'])
    stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345").
      to_return(:body => sample_file('sample_document.doc'))

    Dewey.get('My Document').should_not be_nil
  end
  
  it "returns nil when the title can't be found" do
    Dewey.should_receive(:search).with('My Document', { :exact => true }).and_return([])

    Dewey.get('My Document').should be_nil
  end

  it "is able to download a drawing" do
    stub_request(:get, "#{Dewey::GOOGLE_DRAWING_URL}?docID=12345").
      to_return(:body => sample_file('sample_document.pdf'))

    Dewey.get('drawing:12345').should_not be_nil
  end

  it "is able to download a presentation" do
    stub_request(:get, "#{Dewey::GOOGLE_PRESENTATION_URL}?docID=12345").
      to_return(:body => sample_file('sample_document.pdf'))

    Dewey.get('presentation:12345').should_not be_nil
  end

  it "is able to download a spreadsheet" do
    stub_request(:get, "#{Dewey::GOOGLE_SPREADSHEET_URL}?key=12345").
      to_return(:body => sample_file('sample_spreadsheet.csv'))
    
    Dewey.get('spreadsheet:12345').should_not be_nil
  end

  it "should download a single spreadsheet format sheet" do
    stub_request(:get, "#{Dewey::GOOGLE_SPREADSHEET_URL}?key=12345&exportFormat=csv&gid=1").
      to_return(:body => sample_file('sample_spreadsheet.csv'))

    Dewey.get('spreadsheet:12345', :format => :csv, :sheet => 1).should_not be_nil
  end

  it "should not download a full spreadsheet sheet" do
    stub_request(:get, "#{Dewey::GOOGLE_SPREADSHEET_URL}?key=12345").
      to_return(:body => sample_file('sample_spreadsheet.xls'))
    
    Dewey.get('spreadsheet:12345', :sheet => 1).should_not be_nil
  end

  it "raises when using an unrecognized resourceID" do
    lambda { Dewey.get('video:12345') }.should raise_exception(Dewey::DeweyError)
  end
end
