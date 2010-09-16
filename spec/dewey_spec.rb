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
      @dewey.authorize!.should be_true
    end
    
    it "should return false if authorization fails" do
      @dewey.password = 'mangled'
      @dewey.authorize!.should be_false
    end
    
    it "should store the authorization token on success" do
      @dewey.authorize!
      @dewey.token.should_not be_nil
    end
  end
  
  describe "File operations" do
    before(:all) do
      @dewey = Dewey::Document.new(:account => @credentials['email'], :password => @credentials['password'])
    end
    
    describe "Uploading files" do
      before(:all) do
        @png = sample_file 'invalid_type.png'
        @txt = sample_file 'sample_document.txt'
        # @pre = sample_file 'sample_presentation.ppt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @bad = sample_file 'bad_mimetype'
      end
      
      after(:all) do
        [@png, @txt, @spr, @bad].map(&:close)
      end
    
      it "should raise when uploading unsupported file types" do
        lambda { @dewey.upload(@png) }.should raise_exception(Dewey::DeweyException)
      end
      
      it "should raise when uploading a document with a bad mimetype" do
        lambda { @dewey.upload(@bad) }.should raise_exception(Dewey::DeweyException)
      end
      
      it "should be able to upload" do
        @dewey.upload(@txt).should_not be_nil
        # @dewey.upload(@pre).should_not be_nil
        @dewey.upload(@spr).should_not be_nil
      end
      
      it "should return a resource id" do
        @dewey.upload(@txt).should match(/document:[0-9a-zA-Z]+/)
        @dewey.upload(@spr).should match(/spreadsheet:[0-9a-zA-Z]+/)
      end
      
      it "should authorize automatically" do
        @dewey.upload(@txt)
        @dewey.token.should_not be_nil
      end
    end
  
    describe "Deleting files" do
      before(:each) do
        @txt = sample_file 'sample_document.txt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @txtid = @dewey.upload(@txt)
        @sprid = @dewey.upload(@spr)
      end
      
      after(:each) do
        [@txt, @spr].map(&:close)
      end
      
      it "should accept a known resource id to delete" do
        @dewey.delete(@txtid).should be_true
        @dewey.delete(@sprid).should be_true
      end
    end
  
    describe "Downloading files" do
      before(:all) do
        @txt = sample_file 'sample_document.txt'
        @spr = sample_file 'sample_spreadsheet.xls'
        @txtid = @dewey.upload(@txt)
        @sprid = @dewey.upload(@spr)
      end
      
      after(:all) do
        [@txt, @spr].map(&:close)
        @dewey.delete(@txtid)
        @dewey.delete(@sprid)
      end
      
      it "should be able to download from a known resource id" do
        @dewey.download(@txtid, :doc).should be_kind_of(Tempfile)
        @dewey.download(@sprid, :csv).should be_kind_of(Tempfile)
      end
      
      it "should be able to download the same file repeatably" do
        2.times do
          @dewey.download(@txtid, :doc).should_not be_nil
          @dewey.download(@sprid, :csv).should_not be_nil
        end
      end
    end
  end
end