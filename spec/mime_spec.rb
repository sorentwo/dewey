require 'spec_helper'

describe Dewey::Mime do

  describe "Interpreting mime types from files" do
    it "should provide the correct document mime type" do
      @doc = sample_file 'sample_document.doc'
      @pdf = sample_file 'sample_document.pdf'
      @rtf = sample_file 'sample_document.rtf'

      Dewey::Mime.mime_type(@doc).should eq('application/msword')
      Dewey::Mime.mime_type(@pdf).should eq('application/pdf')
      Dewey::Mime.mime_type(@rtf).should eq('application/rtf')
    end

    it "should provide the correct drawing mime type" do
      @png = sample_file 'sample_drawing.png'

      Dewey::Mime.mime_type(@png).should eq('image/png')
    end

    it "should provide the correct presentation mime type" do
      @ppt = sample_file 'sample_presentation.ppt'

      Dewey::Mime.mime_type(@ppt).should eq('application/vnd.ms-powerpoint')
    end

    it "should provide the correct spreadsheet mime type" do
      @xls = sample_file 'sample_spreadsheet.xls'
      @csv = sample_file 'sample_spreadsheet.csv'

      Dewey::Mime.mime_type(@xls).should eq('application/vnd.ms-excel')
      Dewey::Mime.mime_type(@csv).should eq('text/csv')
    end

    it "should coerce problematic mime types" do
      @docx = sample_file 'sample_document.docx'

      Dewey::Mime.mime_type(@docx).should eq('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    end

    it "should correctly guess from a file without an extension" do
      @noext = sample_file 'sample_document'

      Dewey::Mime.mime_type(@noext).should eq('application/msword')
    end
  end

  describe "Determining file extesion from files" do
    context "when the filename has an extension" do
      it "should pull the extension off the filename" do
        @docx = sample_file 'sample_document.docx'

        Dewey::Mime.extension(@docx).should eq('docx')
      end
    end
    context "when the filename does not have an extension" do
      it "should pull the extension off the filename" do
        @docx = sample_file 'sample_document'

        Dewey::Mime.extension(@docx).should eq('doc')
      end
    end
  end

  describe "Guessing the service from a mime type" do
    it "should correctly guess service when given a known type" do
      Dewey::Mime.guess_service('application/msword').should eq(:document)
      Dewey::Mime.guess_service('application/vnd.ms-powerpoint').should eq(:presentation)
      Dewey::Mime.guess_service('application/x-vnd.oasis.opendocument.spreadsheet').should eq(:spreadsheet)
    end

    it "should return nil for an unknown type" do
      Dewey::Mime.guess_service('bad/example').should be_nil
    end
  end
end
