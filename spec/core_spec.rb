require 'spec_helper'

describe Dewey do
  describe "Establishing Authentication" do
    it "connects lazily" do
      Dewey.authentication :client, :email => 'example', :password => 'password'
      Dewey.authenticated?.should be_false
    end
  end
end
