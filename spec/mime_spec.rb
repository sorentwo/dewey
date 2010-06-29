require 'spec_helper'

describe Dewey::Mime do
    
  describe "Interpreting mime types from files" do
    it "should provide the correct document mime type" do
      @doc = sample_file 'sample_document.doc'
      @pdf = sample_file 'sample_document.pdf'
      @rtf = sample_file 'sample_document.rtf'
      
      Dewey::Mime.mime_type(@doc).should == 'application/msword'
      Dewey::Mime.mime_type(@pdf).should == 'application/pdf'
      Dewey::Mime.mime_type(@rtf).should == 'application/rtf'
    end
    
    it "should provide the correct spreadsheet mime type" do
      @xls = sample_file 'sample_spreadsheet.xls'
      @csv = sample_file 'sample_spreadsheet.csv'
      
      Dewey::Mime.mime_type(@xls).should == 'application/vnd.ms-excel'
      Dewey::Mime.mime_type(@csv).should == 'text/csv'
    end
    
    it "should provide the correct presentation mime type" do
      @ppt = sample_file 'sample_presentation.ppt'
      
      Dewey::Mime.mime_type(@ppt).should == 'application/vnd.ms-powerpoint'
    end
    
    it "should be coerced problematic mime types" do
      @docx = sample_file 'sample_document.docx'
      
      Dewey::Mime.mime_type(@docx).should == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    end
  end
  
  describe "Guessing the service from a mime type" do    
    it "should correctly guess service when given a known type" do
      Dewey::Mime.guess_service('application/msword').should == :document
      Dewey::Mime.guess_service('application/vnd.ms-powerpoint').should == :presentation
    end
    
    it "should return nil for an unknown type" do
      Dewey::Mime.guess_service('bad/example').should be_nil
    end
  end
end