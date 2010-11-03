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
  
  it "authenticates for wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
      with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=example&Passwd=password&service=wise').
      to_return(:body => '=12345')
    
    client_auth.authenticate!(:wise)
    client_auth.authentications.should have_key(:wise)
    
    WebMock.should have_requested(:post, Dewey::GOOGLE_LOGIN_URL).with(:body => /.*service=wise.*/)
  end
  
  it "returns false if authorization fails" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:status => 403)

    client_auth.authenticate!.should be_false
  end

  it "is authenticated with one service" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.authenticate!

    client_auth.authenticated?.should be_true
  end
  
  it "can scope authentication to writely" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    
    client_auth.authenticate!(:writely) 
    client_auth.authenticated?(:writely).should be_true
  end

  it "can scope authentication to wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.authenticate!(:wise)
    client_auth.authenticated?(:wise).should be_true
  end
  
  it "provides authentication tokens" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.authenticate!(:writely)
    
    client_auth.token(:writely).should eq('12345')
  end

  it "authorizes automatically when a token is requested" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.token(:wise).should eq('12345')
  end

  it "can access a token from a string" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.token('writely').should eq('12345') 
  end

  it "will correctly map spreadsheets to wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    client_auth.token('spreadsheets').should eq('12345') 
  end
end
