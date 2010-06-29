require 'spec_helper'
require 'yaml'

describe Dewey::Document do  
  before :all do
    @credentials = YAML.load_file(File.expand_path('../dewey.yml', __FILE__)).each {}
  end
  
  describe "Validation - Checking upload and export file formats" do
    it "should return true for valid upload formats" do
      Dewey::Document.valid_upload_format?('txt', :document).should be_true
      Dewey::Document.valid_upload_format?('ppt', :presentation).should be_true
      Dewey::Document.valid_upload_format?('csv', :spreadsheet).should be_true
    end
    
    it "should return false for invalid upload formats" do
      Dewey::Document.valid_upload_format?('png', :document).should_not be_true
      Dewey::Document.valid_upload_format?('txt', :presentation).should_not be_true
      Dewey::Document.valid_upload_format?('pdf', :spreadsheet).should_not be_true
    end
    
    it "should raise when given an invalid upload service" do
      lambda { Dewey::Document.valid_upload_format?('ical', :cl) }.should raise_exception(Dewey::DeweyException)
    end
    
    it "should return true for valid export formats" do
      Dewey::Document.valid_export_format?('txt', :document).should be_true
      Dewey::Document.valid_export_format?('pdf', :presentation).should be_true
      Dewey::Document.valid_export_format?('csv', :spreadsheet).should be_true
    end
    
    it "should return false for invalid export formats" do
      Dewey::Document.valid_export_format?('jpg', :document).should be_false
      Dewey::Document.valid_export_format?('txt', :presentation).should be_false
      Dewey::Document.valid_export_format?('txt', :spreadsheet).should be_false
    end
    
    it "should raise when given an invalid export service" do
      lambda { Dewey::Document.valid_export_format?('ical', :cl) }.should raise_exception(Dewey::DeweyException)
    end
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
    end
  
    describe "Deleting files" do
      before do      
        @doc = sample_file 'sample_document.txt'
        @rid = @dewey.upload(@doc)
      end
    
      it "should accept a known resource id to delete" do
        @dewey.delete(@rid).should be_true
      end
    end
  
    describe "Downloading files" do    
      it "should be able to download from a known resource id" do
        doc = sample_file 'sample_document.txt'
        spr = sample_file 'sample_spreadsheet.xls'
        
        docid = @dewey.upload(doc)
        sprid = @dewey.upload(spr)
        @dewey.download(docid, :doc).should be_kind_of(Tempfile)
        @dewey.download(sprid, :csv).should be_kind_of(Tempfile)
        @dewey.delete(docid)
        @dewey.delete(sprid)
      end
    end
  end
end