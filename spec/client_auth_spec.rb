require 'spec_helper'

describe Dewey::ClientAuth do

  let(:client_auth) { Dewey::ClientAuth.new('example', 'password') }

  subject { :client_auth }

  it "initializes unauthenticated" do
    client_auth.authenticated?.should be_false
  end

  it "authenticates for writely by default" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
      with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=example&Passwd=password&service=writely').
      to_return(:body => '=12345') 
   
    client_auth.authenticate!.should be_true
    client_auth.authentications.should have_key(:writely)

    WebMock.should have_requested(:post, Dewey::GOOGLE_LOGIN_URL).with(:body => /.*service=writely.*/)
  end
  
  it "returns false if authorization fails" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:status => 403)

    client_auth.authenticate!.should be_false
  end

  it "is authenticated with one authorization" do
    client_auth.stub(:authentications).and_return({ :writely => '12345' })

    client_auth.authenticated?.should be_true
  end
end
