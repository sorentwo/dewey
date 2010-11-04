require 'spec_helper'

describe Dewey do
  describe "Establishing Authentication" do
    it "connects lazily" do
      Dewey.authentication :client, :email => 'example', :password => 'password'
      Dewey.authenticated?.should be_false 
    end
  end
  
  describe "Constructing Headers" do
    it "can omit content-type" do
      Dewey.stub_chain(:authenticator, :token).and_return('12345')
      Dewey.send(:base_headers, false).should_not have_key('Content-Type')
    end
  end
end
