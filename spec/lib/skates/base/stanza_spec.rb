require File.dirname(__FILE__) + '/../../../spec_helper'

describe Skates::Base::Stanza do

  describe "initialize" do

    context "when the stanza is an IQ" do

      before(:each) do
        xml = <<-EOXML 
        <iq type='get'
        from='romeo@montague.net/orchard'
        to='plays.shakespeare.lit'
        id='info1'>
        <query xmlns='http://jabber.org/protocol/disco#configuration'/>
        </iq>
        EOXML
        xml = Nokogiri::XML(xml)
        @stanza = Skates::Base::Stanza.new(xml.root)
      end

      it "should have the right from" do
        @stanza.from.should == "romeo@montague.net/orchard"
      end

      it "should have the right id" do
        @stanza.id.should == "info1"
      end

      it "should have the right to" do
        @stanza.to.should == "plays.shakespeare.lit"
      end

      it "should have the right type" do
        @stanza.type.should == "get"
      end

      it "should have the right name" do
        @stanza.name.should == "iq"
      end
      
    end
    
    
    
    context "when the stanza is a presence" do

      before(:each) do
        xml = <<-EOXML 
        <presence from='firehoser-test.superfeedr.com' to='testparsr@superfeedr.com/skates_client_7008465' type='error' />
        EOXML
        xml = Nokogiri::XML(xml)
        @stanza = Skates::Base::Stanza.new(xml.root)
      end

      it "should have the right from" do
        @stanza.from.should == "firehoser-test.superfeedr.com"
      end

      it "should have the right id" do
        @stanza.id.should be_nil
      end

      it "should have the right to" do
        @stanza.to.should == "testparsr@superfeedr.com/skates_client_7008465"
      end

      it "should have the right type" do
        @stanza.type.should == "error"
      end

      it "should have the right name" do
        @stanza.name.should == "presence"
      end
      
    end
    
    context "when the stanza is a message" do

      before(:each) do
        xml = <<-EOXML 
        <message to="monitor@superfeedr.com" from="test-firehoser.superfeedr.com">
          <event xmlns="http://jabber.org/protocol/pubsub#event">
            <status xmlns="http://superfeedr.com/xmpp-pubsub-ext" feed="http://domain.tld/feed.xml">
              <http code="200">All went very fine. Thanks for asking!</http>
              <next_fetch>2010-02-03T01:32:58+01:00</next_fetch>
              <title></title>
            </status>
          </event>
        </message>
        EOXML
        xml = Nokogiri::XML(xml)
        @stanza = Skates::Base::Stanza.new(xml.root)
      end

      it "should have the right from" do
        @stanza.from.should == "test-firehoser.superfeedr.com"
      end

      it "should have the right id" do
        @stanza.id.should be_nil
      end

      it "should have the right to" do
        @stanza.to.should == "monitor@superfeedr.com"
      end

      it "should have the right type" do
        @stanza.type.should be_nil
      end

      it "should have the right name" do
        @stanza.name.should == "message"
      end
      
    end
    
  end

end