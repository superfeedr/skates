require File.dirname(__FILE__) + '/../../spec_helper'

describe Babylon::XmppConnection do
  
  include BabylonSpecHelper
  
  before(:each) do
    @connection = Babylon::XmppConnection.connect({"jid" => "jid@server", "password" => "password", "port" => 1234, "host" => "myhost.com"}, handler_mock)
    @connection.stub!(:send_data).and_return(true)
  end
  
  describe ".connection_completed" do
    it "should write a log message" do
      Babylon.logger.should_receive(:debug).with("CONNECTED")
      @connection.connection_completed
    end
  end
  
  describe ".unbind" do
    it "should write a log message, and call on_disconnected" do
      Babylon.logger.should_receive(:debug).with("DISCONNECTED")
      handler_mock.should_receive(:on_disconnected)
      @connection.unbind
    end
  end
  
  describe ".receive_stanza" do
    
    before(:each) do
      @doc = Nokogiri::XML::Document.new
    end
    
    it "should write a log message for debug" do
      Babylon.logger.should_receive(:debug).with(/PARSED/)
      @connection.receive_stanza(Nokogiri::XML::Node.new("node", @doc))
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
      
        it "should write an error to the log and raise an error" do
          Babylon.logger.should_receive(:error).with(/DISCONNECTED DUE TO MALFORMED STANZA/)
          lambda {@connection.receive_stanza(@error_stanza)}.should raise_error(Babylon::XmlNotWellFormed)
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
  
  describe ".send_xml" do
    
    before(:each) do
      @connection.instance_variable_set("@connected", true)
      @doc = Nokogiri::XML::Document.new
    end
    
    describe "with a nodeset as argument" do
      before(:each) do
        @iq = Nokogiri::XML::Node.new("iq", @doc)
        @message = Nokogiri::XML::Node.new("message", @doc)
        @presence = Nokogiri::XML::Node.new("presence", @doc)
        @node_set = Nokogiri::XML::NodeSet.new(@doc, [@message, @presence, @iq])
      end
      
      it "should call send_node for each of the nodes in the set" do
        @connection.should_receive(:send_node).with(@iq)
        @connection.should_receive(:send_node).with(@message)
        @connection.should_receive(:send_node).with(@presence)
        @connection.send_xml(@node_set)
      end
      
    end
    
    describe "with a Node as argument" do
      before(:each) do
        @message = Nokogiri::XML::Node.new("message", @doc)
      end
      it "should call send_node for the node" do
        @connection.should_receive(:send_node).with(@message)
        @connection.send_xml(@message)
      end
    end
    
    describe "with a String as argument" do 
      it "should call send_string with the string value of the object" do
        @object = "Hello mon ami!"
        @connection.should_receive(:send_string).with("#{@object}")
        @connection.send_xml(@object)
      end
    end
  end
  
  describe ".send_node" do
    before(:each) do
      @doc = Nokogiri::XML::Document.new
      @message = Nokogiri::XML::Node.new("message", @doc)
      @message["to"] = "you@yourplace.comaaa"
    end
    it "should add a 'from' attribute to the stanza" do
      @connection.__send__(:send_node, @message)
      @message["to"].should_not be_nil
    end
    
    it "should call send_string with the xml value of the node"
  end
  
  describe ".send_string" do
    it "should call send_data" do
      @string = "Hello mon ami"
      @connection.should_receive(:send_data).with(@string).and_return(true)
      @connection.__send__(:send_string, @string)
    end
  end
  
  describe ".receive_data" do
    before(:each) do
      @connection.instance_variable_get("@parser").stub!(:push).and_return(true)
    end
    
    it "should show a message on the log" do
      data = "<hello>hello world!</hello>"
      Babylon.logger.should_receive(:debug).with("RECEIVED : #{data}")
      @connection.__send__(:receive_data, data)
    end
    
    it "should push the received data to the parser" do
      data = "<hello>hello world!</hello>"
      @connection.instance_variable_get("@parser").should_receive(:push).with(data).and_return(true)
      @connection.__send__(:receive_data, data)
    end
  end

end