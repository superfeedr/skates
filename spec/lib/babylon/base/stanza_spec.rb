require File.dirname(__FILE__) + '/../../../spec_helper'

describe Skates::Base::Stanza do
  
  describe "initialize" do
    before(:each) do
      @stanza_string = "<presence />"
      @stanza = Skates::Base::Stanza.new(@stanza_string)
    end
    
    it "should call parse with the string passed to the builder" 
    
  end
  
end