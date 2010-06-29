require 'spec_helper'

describe Dewey::Mime do
    
  describe "Interpreting mime types from files" do
    it "should provide the correct document mime type" do
      @doc = sample_file 'sample_document.doc'
      @pdf = sample_file 'sample_document.pdf'
      @rtf = sample_file 'sample_document.rtf'
      
      Dewey::Mime.mime_type(@doc).should eql('application/msword')
      Dewey::Mime.mime_type(@pdf).should eql('application/pdf')
      Dewey::Mime.mime_type(@rtf).should eql('application/rtf')
    end
    
    it "should provide the correct spreadsheet mime type" do
      @xls = sample_file 'sample_spreadsheet.xls'
      @csv = sample_file 'sample_spreadsheet.csv'
      
      Dewey::Mime.mime_type(@xls).should eql('application/vnd.ms-excel')
      Dewey::Mime.mime_type(@csv).should eql('text/csv')
    end
    
    it "should provide the correct presentation mime type" do
      @ppt = sample_file 'sample_presentation.ppt'
      
      Dewey::Mime.mime_type(@ppt).should eql('application/vnd.ms-powerpoint')
    end
    
    it "should coerce problematic mime types" do
      @docx = sample_file 'sample_document.docx'
      
      Dewey::Mime.mime_type(@docx).should eql('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    end
    
    it "should correctly guess from a file without an extension" do
      @noext = sample_file 'sample_document'
      
      Dewey::Mime.mime_type(@noext).should eql('application/msword')
    end
  end
  
  describe "Guessing the service from a mime type" do    
    it "should correctly guess service when given a known type" do
      Dewey::Mime.guess_service('application/msword').should eql(:document)
      Dewey::Mime.guess_service('application/vnd.ms-powerpoint').should eql(:presentation)
    end
    
    it "should return nil for an unknown type" do
      Dewey::Mime.guess_service('bad/example').should be_nil
    end
  end
end