require 'spec_helper'
require 'yaml'

describe Dewey::Document do
  describe "Authorization - Requesting an auth token" do
    before(:each) do
      @dewey = Dewey::Document.new(:account => 'dewey', :password => 'password')
    end
    
    it "should raise if authorization is attempted with no certs" do
      @dewey.account = @dewey.password = nil
      lambda { @dewey.authorize! }.should raise_exception(Dewey::DeweyException)
    end
    
    it "should raise if authorization is attempted with partial credentials" do
      @dewey.password = nil
      lambda { @dewey.authorize! }.should raise_exception(Dewey::DeweyException)
    end
    
    it "should return true if authorization is successful" do
      stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
        with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=dewey&Passwd=password&service=writely')
      
      @dewey.authorize!.should be_true
    end
    
    it "should return false if authorization fails" do
      stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
        with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=dewey&Passwd=mangled&service=writely').
        to_return(:status => 403)
      
      @dewey.password = 'mangled'
      @dewey.authorize!.should be_false
    end
    
    it "should store the authorization token on success" do
      stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
      
      @dewey.authorize!
      @dewey.token.should eq('12345')
    end
  end
  
  describe "Automatic Authorization" do
    before(:each) do
      @dewey = Dewey::Document.new
      @dewey.stub(:authorize!).and_return(true)
      stub_request(:post, Dewey::GOOGLE_FEED_URL)
    end
    
    it "should automatically authorize when required" do
      @dewey.should_receive(:authorize!)
      @dewey.put(sample_file('sample_document.txt'))
    end
  end
  
  describe "File Operations" do
    before(:each) do
      @dewey = Dewey::Document.new
      @dewey.stub(:authorized?).and_return(true)
    end
    
    describe "#put" do
      before(:all) do
        @png = sample_file 'invalid_type.png'
        @txt = sample_file 'sample_document.txt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @bad = sample_file 'bad_mimetype'
      end
      
      after(:all) do
        [@png, @txt, @spr, @bad].map(&:close)
      end
    
      it "should raise when uploading unsupported file types" do
        lambda { @dewey.put(@png) }.should raise_exception(Dewey::DeweyException)
      end
      
      it "should raise when uploading a document with a bad mimetype" do
        lambda { @dewey.put(@bad) }.should raise_exception(Dewey::DeweyException)
      end

      it "get a resource id after putting a document" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<fake><id>document%3A12345</id></fake>")
        
        @dewey.put(@txt).should eq('document:12345')
      end
      
      it "get a resource id after putting a spreadsheet" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<fake><id>spreadsheet%3A12345</id></fake>")
          
        @dewey.put(@spr).should eq('spreadsheet:12345')
      end
    end
  
    describe "#delete" do
      it "should delete a resource from an id" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345")
        @dewey.delete('document:12345').should be_true
      end
    end
  
    describe "#get" do      
      it "should be able to download a document" do
        stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345&exportFormat=doc").
          to_return(:body => sample_file('sample_document.doc'))
        
        @dewey.get('document:12345', :doc).should be_kind_of(Tempfile)
      end
      
      it "should be able to download a spreadsheet" do
        stub_request(:get, "#{Dewey::GOOGLE_SPREADSHEET_URL}?key=12345&exportFormat=csv").
          to_return(:body => sample_file('sample_spreadsheet.csv'))
        
        @dewey.get('spreadsheet:12345', :csv).should be_kind_of(Tempfile)
      end
      
      it "should be able to download the same document repeatedly" do
        stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345&exportFormat=doc").
          to_return(:body => sample_file('sample_document.doc'))
        
        2.times do
          @dewey.get('document:12345', :doc).should be_kind_of(Tempfile)
        end
      end
    end
    
    describe "#convert" do
      before(:each) do
        @txt = sample_file 'sample_document.txt'
        @doc = sample_file 'sample_document.doc'
        @dewey.stub(:authorize!).and_return(true, true, true)
      end
      
      it "should put, get, and delete" do
        @dewey.should_receive(:put).with(@txt, 'sample').and_return('document:12345')
        @dewey.should_receive(:get).with('document:12345', :doc).and_return(@doc)
        @dewey.should_receive(:delete).with('document:12345').and_return(true)
        @dewey.convert(@txt, :title => 'sample', :format => :doc).should be(@doc)
      end
    end
  end
end