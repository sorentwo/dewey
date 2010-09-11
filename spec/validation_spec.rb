require 'spec_helper'

describe Dewey::Validation do
  
  it "should return true for valid upload formats" do
    Dewey::Validation.valid_upload_format?('txt', :document).should be_true
    Dewey::Validation.valid_upload_format?('ppt', :presentation).should be_true
    Dewey::Validation.valid_upload_format?('csv', :spreadsheet).should be_true
  end

  it "should return false for invalid upload formats" do
    Dewey::Validation.valid_upload_format?('png', :document).should_not be_true
    Dewey::Validation.valid_upload_format?('txt', :presentation).should_not be_true
    Dewey::Validation.valid_upload_format?('pdf', :spreadsheet).should_not be_true
  end

  it "should raise when given an invalid upload service" do
    lambda { Dewey::Validation.valid_upload_format?('ical', :cl) }.should raise_exception(Dewey::DeweyException)
  end

  it "should return true for valid export formats" do
    Dewey::Validation.valid_export_format?('txt', :document).should be_true
    Dewey::Validation.valid_export_format?('pdf', :presentation).should be_true
    Dewey::Validation.valid_export_format?('csv', :spreadsheet).should be_true
  end

  it "should return false for invalid export formats" do
    Dewey::Validation.valid_export_format?('jpg', :document).should be_false
    Dewey::Validation.valid_export_format?('txt', :presentation).should be_false
    Dewey::Validation.valid_export_format?('txt', :spreadsheet).should be_false
  end

  it "should raise when given an invalid export service" do
    lambda { Dewey::Validation.valid_export_format?('ical', :cl) }.should raise_exception(Dewey::DeweyException)
  end
end