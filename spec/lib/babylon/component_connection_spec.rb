require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../em_mock'

describe Babylon::ComponentConnection do

  include BabylonSpecHelper

  before(:each) do
    @params = {"jid" => "jid@server", "password" => "password", "port" => 1234, "host" => "myhost.com"}
    @component = Babylon::ComponentConnection.connect(@params, handler_mock) 
    @component.stub!(:send_xml).and_return(true) 
  end

  describe "initialize" do
    it "should set the state to :wait_for_stream" do
      @component.instance_variable_get("@state").should == :wait_for_stream
    end
  end

  describe "connection_completed" do
    it "should send a <stream> element that initiates the communication" do
      @component.should_receive(:send_xml).with("<?xml version=\"1.0\"?>\n<stream:stream xmlns=\"jabber:component:accept\" xmlns:stream=\"http://etherx.jabber.org/streams\" to=\"jid@server\">\n  ")
      @component.connection_completed
    end
  end

  describe "receive_stanza" do

    before(:each) do
      @component.instance_variable_set("@connected", true)
      @doc = Nokogiri::XML::Document.new
      @stanza = Nokogiri::XML::Node.new("presence", @doc)
    end

    describe "when connected" do
      before(:each) do
        @component.instance_variable_set("@state", :connected)
      end
      it "should call the receive_stanza on super" 
    end

    describe "when waiting for stream" do
      before(:each) do
        @component.connection_completed
        @component.instance_variable_set("@state", :wait_for_stream)
      end

      describe "if the stanza is stream" do
        before(:each) do
          @stanza = Nokogiri::XML::Node.new("stream:stream", @doc)
          @stanza["xmlns:stream"] = 'http://etherx.jabber.org/streams'
          @stanza["xmlns"] = 'jabber:component:accept'
          @stanza["from"] = 'plays.shakespeare.lit'
          @stanza["id"] = "1234"
        end

        it "should send a handshake" do
          @component.should_receive(:handshake)
          @component.receive_stanza(@stanza)
        end

        it "should change state to wait_for_handshake" do
          @component.receive_stanza(@stanza)
          @component.instance_variable_get("@state").should == :wait_for_handshake
        end

      end

      describe "if the stanza is not stream or deosn't have an id" do
        it "should raise an error" do
          lambda {@component.receive_stanza(Nokogiri::XML::Node.new("else", @doc))}.should raise_error
        end
      end

    end

    describe "when waiting for handshake" do
      before(:each) do
        @component.instance_variable_set("@state", :wait_for_handshake)
      end

      describe "if we actually get a handshake stanza" do

        before(:each) do
          @handshake = Nokogiri::XML::Node.new("handshake", @doc)
        end

        it "should set the status as connected" do
          @component.receive_stanza(@handshake)
          @component.instance_variable_get("@state").should == :connected
        end

        it "should call the connection callback" do
          handler_mock.should_receive(:on_connected).with(@component)
          @component.receive_stanza(@handshake)
        end
      end

      describe "if we receive a stream:error" do
        it "should raise an Authentication Error" do
          lambda {@component.receive_stanza(Nokogiri::XML::Node.new("stream:error", @doc))}.should raise_error(Babylon::AuthenticationError)
        end
      end

      describe "if we receive something else" do
        it "should raise an error" do
          lambda {@component.receive_stanza(Nokogiri::XML::Node.new("else", @doc))}.should raise_error
        end
      end

    end

  end

  describe "stream_namespace" do
    it "should return jabber:component:accept" do
      @component.stream_namespace.should == 'jabber:component:accept'
    end
  end

  describe "handshake" do
    it "should build a handshake Element with the password and the id of the stanza" do
      @component.connection_completed
      doc = Nokogiri::XML::Document.new
      stanza = Nokogiri::XML::Node.new("stream:stream", doc)
      stanza["xmlns:stream"] = 'http://etherx.jabber.org/streams'
      stanza["xmlns"] = 'jabber:component:accept'
      stanza["from"] = 'plays.shakespeare.lit'
      stanza["id"] = "1234"
      @component.__send__(:handshake, stanza).xpath("//handshake").first.content.should == Digest::SHA1::hexdigest(stanza.attributes['id'].content + @params["password"])
    end
    
  end

end