require 'spec_helper'

describe Dewey::Mime do
  let(:csv)  { sample_file 'sample_spreadsheet.csv' }
  let(:doc)  { sample_file 'sample_document.doc' }
  let(:docx) { sample_file 'sample_document.docx' }
  let(:nxt)  { sample_file 'sample_document' }
  let(:pdf)  { sample_file 'sample_document.pdf' }
  let(:png)  { sample_file 'sample_drawing.png' }
  let(:ppt)  { sample_file 'sample_presentation.ppt' }
  let(:rtf)  { sample_file 'sample_document.rtf' }
  let(:xls)  { sample_file 'sample_spreadsheet.xls' }

  describe "Interpreting mime types from files" do
    it "should provide the correct document mime type" do
      Dewey::Mime.mime_type(doc).should eq('application/msword')
      Dewey::Mime.mime_type(pdf).should eq('application/pdf')
      Dewey::Mime.mime_type(rtf).should eq('application/rtf')
    end

    it "should provide the correct drawing mime type" do
      Dewey::Mime.mime_type(png).should eq('image/png')
    end

    it "should provide the correct presentation mime type" do
      Dewey::Mime.mime_type(ppt).should eq('application/vnd.ms-powerpoint')
    end

    it "should provide the correct spreadsheet mime type" do
      Dewey::Mime.mime_type(xls).should eq('application/vnd.ms-excel')
      Dewey::Mime.mime_type(csv).should eq('text/csv')
    end

    it "should coerce problematic mime types" do

      Dewey::Mime.mime_type(docx).should eq('application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    end

    it "should correctly guess from a file without an extension" do
      Dewey::Mime.mime_type(nxt).should eq('application/msword')
    end
  end

  describe "Determining file extesion from files" do
    context "when the filename has an extension" do
      it "should pull the extension off the filename" do
        Dewey::Mime.extension(docx).should eq('docx')
      end
    end
    context "when the filename does not have an extension" do
      it "should pull the extension off the filename" do
        Dewey::Mime.extension(nxt).should eq('doc')
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
