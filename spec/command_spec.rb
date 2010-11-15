require 'spec_helper'
require 'dewey/command'

describe Dewey::Command do
  def dewey_command(args)
    cmd = Dewey::Command.new(args.split(' '))
    begin
      cmd.run(@out_stream, @err_stream)
    rescue SystemExit
    end
  end

  def out_stream
    @out_stream.rewind
    @out_stream.read
  end

  before(:each) do
    Kernel.stub!(:exit).and_return(0)
    
    @out_stream = StringIO.new
    @err_stream = StringIO.new
  end

  describe 'Version' do
    it "should give the current version" do
      dewey_command('-v')
      out_stream.should include(Dewey::VERSION)
    end
  end

  describe 'Help' do
    it "should give help info" do
      dewey_command('-h')
      out_stream.should_not be_blank
    end
  end
end
