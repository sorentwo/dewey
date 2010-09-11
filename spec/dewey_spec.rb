require 'spec_helper'
require 'yaml'

describe Dewey::Document do  
  before :all do
    @credentials = YAML.load_file(File.expand_path('../dewey.yml', __FILE__)).each {}
  end
  
  describe "Authorization - Requesting an auth token" do
    before do
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
      @dewey.authorize!.should be_true
    end
    
    it "should return false if authorization fails" do
      @dewey.password = 'mangled'
      @dewey.authorize!.should be_false
    end
    
    it "should store the authorization token on success" do
      @dewey.token.should be_nil
      @dewey.authorize!
      @dewey.token.should_not be_nil
    end
  end
  
  describe "File operations" do
    before(:all) do
      @dewey = Dewey::Document.new(:account => @credentials['email'], :password => @credentials['password'])
      @dewey.authorize!
    end
  
    describe "Uploading files" do
      before do
        @doc = sample_file 'sample_document.txt'
        @pre = sample_file 'sample_presentation.ppt'
        @spr = sample_file 'sample_spreadsheet.xls'
      end
    
      it "should raise when attempting to upload unsupported file types" do
        png = sample_file 'invalid_type.png'
        lambda { @dewey.upload(png) }.should raise_exception(Dewey::DeweyException)
      end
    
      it "should be able to upload" do
        @dewey.upload(@doc).should_not be_nil
        # @dewey.upload(@pre).should_not be_nil
        @dewey.upload(@spr).should_not be_nil
      end
      
      it "should return a resource id" do
        @dewey.upload(@doc).should match(/document:[0-9a-zA-Z]+/)
        @dewey.upload(@spr).should match(/spreadsheet:[0-9a-zA-Z]+/)
      end
    
      it "should update the cache when upload is successful" do      
        @dewey.upload(@doc)
        @dewey.cached.should_not be_empty
        @dewey.cached['sample_document'].should_not be_nil
      end
      
      # It is often the case on OS X that TextEdit or Pages has made a .doc file.
      # In these cases a mime type won't be accurately determined and we should
      # let Google do the hard work.
      it "should upload a document with no Content-Type when necessary" do
        @bad = sample_file 'bad_mimetype'
        lambda { @dewey.upload(@bad) }.should_not raise_exception(Dewey::DeweyException)
      end
    end
  
    describe "Deleting files" do
      before do      
        @txt = sample_file 'sample_document.txt'
        @rid = @dewey.upload(@txt)
      end
    
      it "should accept a known resource id to delete" do
        @dewey.delete(@rid).should be_true
      end
    end
  
    describe "Downloading files" do    
      it "should be able to download from a known resource id" do
        txt = sample_file 'sample_document.txt'
        spr = sample_file 'sample_spreadsheet.xls'
        
        txtid = @dewey.upload(txt)
        sprid = @dewey.upload(spr)
        @dewey.download(txtid, :doc).should be_kind_of(Tempfile)
        @dewey.download(sprid, :csv).should be_kind_of(Tempfile)
        @dewey.delete(txtid)
        @dewey.delete(sprid)
      end
    end
  end
end