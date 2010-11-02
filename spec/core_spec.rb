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
    
    describe "#put" do
      before(:all) do
        @psd = sample_file 'sample_drawing.psd'
        @txt = sample_file 'sample_document.txt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @bad = sample_file 'bad_mimetype'
      end
      
      after(:all) do
        [@psd, @txt, @spr, @bad].map(&:close)
      end
    
      it "should raise when uploading unsupported file types" do
        lambda { Dewey.put(@psd) }.should raise_exception(Dewey::DeweyException)
      end
      
      it "should raise when uploading a document with a bad mimetype" do
        lambda { Dewey.put(@bad) }.should raise_exception(Dewey::DeweyException)
      end

      it "should return nil on a failed request" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).to_return(:status => 300)

        Dewey.put(@txt).should be_nil
      end

      it "get a resource id after putting a document" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<feed><entry><id>https://docs.google.com/feeds/id/document:12345</id></entry></feed>")
        
        Dewey.put(@txt).should eq('document:12345')
      end
      
      it "get a resource id after putting a spreadsheet" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).
          to_return(:status => 201, :body => "<feed><entry><id>https://docs.google.com/feeds/id/spreadsheet:12345</id></entry></feed>")
          
        Dewey.put(@spr).should eq('spreadsheet:12345')
      end

      it "specifies an optional title in the header" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL)
        Dewey.put(@txt, :title => 'Secret')

        a_request(:post, Dewey::GOOGLE_FEED_URL).
          with(:headers => { 'Slug' => 'Secret' }).should have_been_made
      end

      it "specifies the filesize in the header" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL)
        Dewey.put(@txt)

        a_request(:post, Dewey::GOOGLE_FEED_URL).
          with(:headers => { 'Content-Length' => @txt.size }).should have_been_made
      end
    end

    describe "#put!" do
      before(:all) do
        @txt = sample_file 'sample_document.txt'
      end
      
      after(:all) { @txt.close }

      it "raises an error on a failed request" do
        stub_request(:post, Dewey::GOOGLE_FEED_URL).to_return(:status => 300)
        lambda { Dewey.put!(@txt) }.should raise_exception(Dewey::DeweyException)
      end
    end

    describe "#delete" do
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
  
    describe "#delete!" do
      it "raises an error when a resource can't be found" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345?delete=true").to_return(:status => 300)
        lambda { Dewey.delete!('document:12345') }.should raise_exception(Dewey::DeweyException)
      end

      it "doesn't delete with the trash option" do
        stub_request(:delete, "#{Dewey::GOOGLE_FEED_URL}/document:12345")
        Dewey.delete!('document:12345', :trash => true).should be_true
      end
    end

    describe "#get" do 
      it "raises with an invalid format" do
        lambda { Dewey.get('document:12345', :format => :psd) }.should raise_exception(Dewey::DeweyException)
      end

      it "returns a tempfile" do
        stub_request(:get, /.*/).to_return(:body => sample_file('sample_document.txt'))

        Dewey.get('document:12345').should be_kind_of(Tempfile)
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
        lambda { Dewey.get('video:12345') }.should raise_exception(Dewey::DeweyException)
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
