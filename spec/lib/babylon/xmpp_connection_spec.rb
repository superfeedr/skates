require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../em_mock'

describe Skates::XmppConnection do
  
  include SkatesSpecHelper
  
  before(:each) do
    @params = {"jid" => "jid@server", "password" => "password", "port" => 1234, "host" => "myhost.com"}
    @connection = Skates::XmppConnection.connect(@params, handler_mock)
  end
  
  describe "connect" do    
    it "should connect EventMachine and return it" do
      EventMachine.should_receive(:connect).with(@params["host"], @params["port"], Skates::XmppConnection, hash_including("handler" => handler_mock)).and_return(@connection)
      Skates::XmppConnection.connect(@params, handler_mock).should == @connection
    end
    
    it "should rescue Connection Errors" do
      EventMachine.stub!(:connect).with(@params["host"], @params["port"], Skates::XmppConnection, hash_including("handler" => handler_mock)).and_raise(RuntimeError)
      lambda {
        Skates::XmppConnection.connect(@params, handler_mock)
      }.should raise_error(Skates::NotConnected)
    end

  end
  
  describe "initialize" do
    it "should assign @connected to false" do
      @connection.instance_variable_get("@connected").should be_false
    end
    
    it "should assign @jid to params['jid']" do
      @connection.instance_variable_get("@jid").should == @params["jid"]
    end
    
    it "should assign @password to params['password']" do
      @connection.instance_variable_get("@password").should == @params["password"]
    end
    
    it "should assign @host to params['host']" do
      @connection.instance_variable_get("@host").should == @params["host"]
    end
    
    it "should assign @port to params['port']" do
      @connection.instance_variable_get("@port").should == @params["port"]
    end
    
    it "should assign @handler to params['handler']" do
      @connection.instance_variable_get("@handler").should == handler_mock
    end
    
    it "should assign @buffer to ''" do
      @connection.instance_variable_get("@buffer").should == ""
    end
  end
  
  describe "post_init" do
    it "assigne a new parser" do
      parser = Skates::XmppParser.new(@connection.method(:receive_stanza))
      Skates::XmppParser.should_receive(:new).and_return(parser)
      @connection.post_init
      @connection.instance_variable_get("@parser").should == parser
    end
  end
  
  describe "connection_completed" do
    it "should set @connected to true" do
      @connection.connection_completed
      @connection.instance_variable_get("@connected").should be_true
    end
  end
  
  describe "unbind" do
    it "should set @connected to false" do
      @connection.connection_completed
      @connection.unbind
      @connection.instance_variable_get("@connected").should be_false
    end
  end
  
  describe "receive_stanza" do
    
    before(:each) do
      @doc = Nokogiri::XML::Document.new
    end
    
    describe "with an stanza that starts with stream:error" do
      
      before(:each) do
        @error_stanza = Nokogiri::XML::Node.new("stream:error", @doc)
      end
      
      it "should close the connection" do
        @connection.should_receive(:close_connection)
        @connection.receive_stanza(@error_stanza)
      end
      
      describe "with a malformed stanza error" do
         before(:each) do
           @xml_not_well_formed_stanza = Nokogiri::XML::Node.new("xml-not-well-formed", @doc)
           @xml_not_well_formed_stanza.add_namespace("xmlns", "urn:ietf:params:xml:ns:xmpp-streams")
           @error_stanza.add_child(@xml_not_well_formed_stanza)
         end
      
      end
    end
    
    describe "with a stanza that is not an error" do
      it "should call the on_stanza block" do
        stanza = Nokogiri::XML::Node.new("message", @doc)
        handler_mock.should_receive(:on_stanza)
        @connection.receive_stanza(stanza)
      end
    end
    
  end
  
  describe "send_chunk" do
    it "should raise an error if not connected" do
      @connection.instance_variable_set("@connected", false)
      lambda {
        @connection.__send__(:send_chunk, "hello world")
      }.should raise_error(Skates::NotConnected)
    end
    
    it "should raise an error if the stanza size is above the limit" do
      @connection.instance_variable_set("@connected", true)
      string = "a" * (Skates::XmppConnection.max_stanza_size + 1)
      lambda {
        @connection.__send__(:send_chunk, string)
      }.should raise_error(Skates::StanzaTooBig)
    end
    
    it "should return if the string is blank" do
      @connection.instance_variable_set("@connected", true)
      @connection.should_not_receive(:send_data)
      @connection.__send__(:send_chunk, "")
    end
    
    it "should cann send_data with the string" do
      @connection.instance_variable_set("@connected", true)
      string = "hello world"
      @connection.should_receive(:send_data).with(string)
      @connection.__send__(:send_chunk, string)    
    end
    
  end
  
  describe "send_xml" do
    
    before(:each) do
      @connection.instance_variable_set("@connected", true)
      @connection.stub!(:send_chunk).and_return(true)
      @doc = Nokogiri::XML::Document.new
    end
    
    describe "with a nodeset as argument" do
      before(:each) do
        iq = Nokogiri::XML::Node.new("iq", @doc)
        message = Nokogiri::XML::Node.new("message", @doc)
        presence = Nokogiri::XML::Node.new("presence", @doc)
        @node_set = Nokogiri::XML::NodeSet.new(@doc, [message, presence, iq])
      end
      
      it "should call send_chunk for each of the nodes in the set" do
        @node_set.each do |node|
          @connection.should_receive(:send_chunk).with(node.to_s)
        end
        @connection.send_xml(@node_set)
      end
    end
    
    describe "with an argument with is not a NodeSet" do
      before(:each) do
        @message = Nokogiri::XML::Node.new("message", @doc)
      end
      it "should call send_chunk for the node" do
        @connection.should_receive(:send_chunk).with(@message.to_s)
        @connection.send_xml(@message)
      end
    end
  end
  
  describe "receive_data" do
    before(:each) do
      @connection.instance_variable_get("@parser").stub!(:push).and_return(true)
    end
    
    it "should push the received data to the parser" do
      data = "<hello>hello world!</hello>"
      @connection.instance_variable_get("@parser").should_receive(:push).with(data).and_return(true)
      @connection.__send__(:receive_data, data)
    end
  end

end