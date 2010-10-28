require 'spec_helper'

describe Dewey do
  describe "Establishing Authentication" do
    it "connects lazily" do
      Dewey.authentication :client, :email => 'example', :password => 'password'
      Dewey.authenticated?.should be_false 
    end
    
    it "automatically authenticates when required" do
      stub_request(:post, Dewey::GOOGLE_FEED_URL)
      Dewey.stub(:authenticate!).and_return(true)
      Dewey.should_receive(:authenticate!)
      Dewey.put(sample_file('sample_document.txt'))
    end
  end
  
  describe "Constructing Headers" do
    it "does not set Authorization headers without authentication" do
      Dewey.send(:base_headers).should_not have_key('Authorization')
    end
    
    it "has Authorization headers with authentication" do
      Dewey.stub(:authenticated?).and_return(true)
      Dewey.send(:base_headers).should have_key('Authorization')
    end

    it "can omit content-type" do
      Dewey.send(:base_headers, false).should_not have_key('Content-Type')
    end
  end
  
  describe "File Operations" do
    before(:each) do
      Dewey.stub(:authenticated?).and_return(true)
    end
   
    describe "#search" do
      it "can exactly match a single document" do
        stub_request(:get, "#{Dewey::GOOGLE_FEED_URL}?title=HR+Handbook&title-exact=true").
          to_return(:body => '<feed><entry><id>document:12345</id></entry></feed>')
        
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
        lambda { Dewey.put(@png) }.should raise_exception(Dewey::DeweyException)
      end
      
      it "should raise when uploading a document with a bad mimetype" do
        lambda { Dewey.put(@bad) }.should raise_exception(Dewey::DeweyException)
      end

      it "get a resource id after putting a document" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<fake><id>document%3A12345</id></fake>")
        
        Dewey.put(@txt).should eq('document:12345')
      end
      
      it "get a resource id after putting a spreadsheet" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<fake><id>spreadsheet%3A12345</id></fake>")
          
        Dewey.put(@spr).should eq('spreadsheet:12345')
      end
    end
  
    describe "#delete" do
      it "deletes a resource from an id" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true")
        Dewey.delete('document:12345').should be_true
      end

      it "reports false when a resource can't be found" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").to_return(:status => 300)
        Dewey.delete('document:12345').should be_false
      end
    end
  
    describe "#delete!" do
      it "raises an error when a resource can't be found" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").to_return(:status => 300)
        lambda { Dewey.delete!('document:12345') }.should raise_exception(Dewey::DeweyException)
      end
    end

    describe "#get" do 
      it "is able to download a document" do
        stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345&exportFormat=doc").
          to_return(:body => sample_file('sample_document.doc'))
        
        Dewey.get('document:12345', :doc).should be_kind_of(Tempfile)
      end
      
      it "is able to download a spreadsheet" do
        stub_request(:get, "#{Dewey::GOOGLE_SPREADSHEET_URL}?key=12345&exportFormat=csv").
          to_return(:body => sample_file('sample_spreadsheet.csv'))
        
        Dewey.get('spreadsheet:12345', :csv).should be_kind_of(Tempfile)
      end
      
      it "is able to download the same document repeatedly" do
        stub_request(:get, "#{Dewey::GOOGLE_DOCUMENT_URL}?docID=12345&exportFormat=doc").
          to_return(:body => sample_file('sample_document.doc'))
        
        2.times do
          Dewey.get('document:12345', :doc).should be_kind_of(Tempfile)
        end
      end
    end
    
    describe "#convert" do
      before(:each) do
        @txt = sample_file 'sample_document.txt'
        @doc = sample_file 'sample_document.doc'
        Dewey.stub(:authorize!).and_return(true, true, true)
      end
      
      it "should put, get, and delete" do
        Dewey.should_receive(:put).with(@txt, 'sample').and_return('document:12345')
        Dewey.should_receive(:get).with('document:12345', :doc).and_return(@doc)
        Dewey.should_receive(:delete).with('document:12345').and_return(true)
        Dewey.convert(@txt, :title => 'sample', :format => :doc).should be(@doc)
      end
    end
  end
end
