require File.dirname(__FILE__) + '/../../spec_helper'

describe Babylon::XmppParser do
  
  describe ".callbacks" do
    
    before(:each) do
      @last_stanza = ""
      @parser = Babylon::XmppParser.new 
      @parser.elem = Nokogiri::XML::Element.new("element", @parser.doc)
    end
  
    describe ".cdata_block" do
      it "should create a CData block in the current element when called directly" do
        @parser.cdata_block("salut my friend!")
        @parser.elem.to_xml.should == "<element><![CDATA[salut my friend!]]></element>"
      end
      
      it "should call the cdata_block when the content contains <![CDATA" do
        @parser.should_receive(:cdata_block).with("salut my friend!")
        @parser.push("<hello><![CDATA[salut my friend!]]></hello>")        
      end
      
      it "should create a CDATA block in the current element when a CData block is pushed" do
        @parser.push("<hello><![CDATA[salut my friend!]]></hello>")
        @parser.elem.to_xml.should == "<element><hello><![CDATA[salut my friend!]]></hello></element>"
      end
      
      
    end
  end
  
end