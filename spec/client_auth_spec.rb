require 'spec_helper'

describe Dewey::ClientAuth do

  subject { Dewey::ClientAuth.new('example', 'password') }

  it "initializes unauthenticated" do
    subject.authenticated?.should be_false
  end

  it "authenticates for writely by default" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
      with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=example&Passwd=password&service=writely').
      to_return(:body => '=12345')
   
    subject.authenticate!.should be_true
    subject.authentications.should have_key(:writely)

    WebMock.should have_requested(:post, Dewey::GOOGLE_LOGIN_URL).with(:body => /.*service=writely.*/)
  end
  
  it "authenticates for wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).
      with(:body => 'accountType=HOSTED_OR_GOOGLE&Email=example&Passwd=password&service=wise').
      to_return(:body => '=12345')
    
    subject.authenticate!(:wise)
    subject.authentications.should have_key(:wise)
    
    WebMock.should have_requested(:post, Dewey::GOOGLE_LOGIN_URL).with(:body => /.*service=wise.*/)
  end
  
  it "returns false if authorization fails" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:status => 403)

    subject.authenticate!.should be_false
  end

  it "raises when it gets a wacky response" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:status => 500)

    lambda { subject.authenticate! }.should raise_exception(Dewey::DeweyError)
  end

  it "is authenticated with one service" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.authenticate!

    subject.authenticated?.should be_true
  end
  
  it "can scope authentication to writely" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    
    subject.authenticate!(:writely) 
    subject.authenticated?(:writely).should be_true
  end

  it "can scope authentication to wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.authenticate!(:wise)
    subject.authenticated?(:wise).should be_true
  end
  
  it "provides authentication tokens" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.authenticate!(:writely)
    
    subject.token(:writely).should eq('12345')
  end

  it "authorizes automatically when a token is requested" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.token(:wise).should eq('12345')
  end

  it "will correctly map documents to writely" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.token('document').should eq('12345')
  end

  it "will correctly map spreadsheets to wise" do
    stub_http_request(:post, Dewey::GOOGLE_LOGIN_URL).to_return(:body => '=12345')
    subject.token('spreadsheets').should eq('12345') 
  end
end
