# -*- encoding: utf-8 -*-

require 'spec_helper'

describe Dewey::Utils do
  describe '#slug' do
    it "should not replace spaces with '+'" do
      Dewey::Utils.slug('this has spaces').should eq('this has spaces')
    end

    it "should ignore most printing characters" do
      Dewey::Utils.slug(' !"#$').should eq(' !"#$')
    end

    it "should escape %" do
      Dewey::Utils.slug('%').should eq('%25')
    end

    it "should percent encode foreign characters" do
      Dewey::Utils.slug('ø').should eq('%C3')
    end
  end
end
