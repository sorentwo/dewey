require 'spec_helper'
require 'yaml'

describe Dewey::Document do  
  before(:all) do
    @credentials = YAML.load_file(File.expand_path('../dewey.yml', __FILE__)).each {}
  end
  
  describe "Authorization - Requesting an auth token" do
    before(:each) do
      @dewey = Dewey::Document.new(:account => @credentials['email'], :password => @credentials['password'])
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
      stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL)
      
      @dewey.authorize!.should be_true
    end
    
    it "should return false if authorization fails" do
      stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:status => 403)
      
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
      before(:all) do
        @txt = sample_file 'sample_document.txt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @txtid = @dewey.upload(@txt)
        @sprid = @dewey.upload(@spr)
      end
      
      after(:all) do
        [@txt, @spr].map(&:close)
      end
      
      it "should be able to download from a known resource id" do
        @dewey.get(@txtid, :doc).should be_kind_of(Tempfile)
        @dewey.get(@sprid, :csv).should be_kind_of(Tempfile)
      end
      
      it "should be able to download the same file repeatably" do
        2.times do
          @dewey.get(@txtid, :doc).should_not be_nil
          @dewey.get(@sprid, :csv).should_not be_nil
        end
      end
    end
  end
end