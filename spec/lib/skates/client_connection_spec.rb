require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../em_mock'

describe Skates::ClientConnection do
  
  include SkatesSpecHelper

  before(:each) do
    @params = {"jid" => "jid@server.tld", "password" => "password"}
    @client = Skates::ClientConnection.connect(@params.merge({"host" => "0.0.0.0", "port" => 5222}), handler_mock) 
    @client.stub!(:send_xml).and_return(true) 
  end
  
  describe "initialize" do
    it "should set the state to :wait_for_stream" do
      @client.instance_variable_get("@state").should == :wait_for_stream
    end
  end
  
  describe "connect" do
  end
  
  describe "when resolving the hostname" do
    before(:each) do
      @params.delete("host")
      @params.delete("port")
      @srv = [
        mock(Resolv::DNS::Resource, :priority => 10, :target => "12.13.14.15", :port => 1234, :address => "12.13.14.15"),
        mock(Resolv::DNS::Resource, :priority => 3, :target => "12.13.14.16", :port => 4567, :address => "12.13.14.16"),
        mock(Resolv::DNS::Resource, :priority => 100, :target => "12.13.14.17", :port => 8910, :address => "12.13.14.17")
        ]
      @mock_dns = mock(Object)
      Resolv::DNS.stub!(:open).and_yield(@mock_dns)
      @mock_dns.stub!(:getresources).and_return(@srv)
    end
    
    it "should get resources assiated with _xmpp-client._tcp.host.tld}" do
      Resolv::DNS.should_receive(:open).and_yield(@mock_dns)
      @mock_dns.should_receive(:getresources).with("_xmpp-client._tcp.server.tld", Resolv::DNS::Resource::IN::SRV).and_return(@srv)
      Skates::ClientConnection.resolve("server.tld") 
    end
    
    it "should call the block with the highest priority" do
      Skates::ClientConnection.resolve("xmpp.server.tld") do |params|
        params["host"].should == "12.13.14.17"
        params["port"].should == 8910
        true
      end 
    end
    
    it "should call the block as many times as needed if they're not connecting" do
      conn = mock(Skates::ClientConnection, :_connect => false)
      conn.should_receive(:_connect).exactly(3).times
      Skates::ClientConnection.resolve("xmpp.server.tld") do |ip, port|
        conn._connect(ip, port)
      end
    end
  end
  
  describe "stream_stanza" do
    it "should be of the right form" do
      @client.stream_stanza.should == "<?xml version=\"1.0\"?>\n<stream:stream xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\" to=\"server.tld\" version=\"1.0\">\n  "
    end
  end
  
  describe "connection_completed" do
    it "should send_xml the stream_stanza" do
      @client.should_receive(:send_xml).with(@client.stream_stanza)
      @client.connection_completed
    end
  end
  
  describe "receive_stanza" do
    before(:each) do
      @doc = Nokogiri::XML::Document.new
    end
    describe "when connected" do
      before(:each) do
        @client.instance_variable_set("@state", :connected)
      end
      it "should call super"
    end
    
    describe "when wait_for_stream_authenticated" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_stream_authenticated)
        @stanza = Nokogiri::XML::Node.new("stream", @doc)
        @stanza["id"] = "123"
      end
      it "should change state to wait_for_bind if the stanza is stream with an id" do
        @client.receive_stanza(@stanza)
        @client.instance_variable_get("@state").should == :wait_for_bind
      end
    end
    
    describe "when wait_for_stream" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_stream)
        @stanza = Nokogiri::XML::Node.new("stream", @doc)
        @stanza["id"] = "123"
      end
      it "should change state to wait_for_auth_mechanisms if the stanza is stream with an id" do
        @client.receive_stanza(@stanza)
        @client.instance_variable_get("@state").should == :wait_for_auth_mechanisms
      end
    end
    
    describe "when wait_for_auth_mechanisms" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_auth_mechanisms)
      end
      
      describe "if the stanza is features" do
        before(:each) do
          @stanza = Nokogiri::XML::Node.new("features", @doc)
          @stanza["id"] = "123"
        end
        
        describe "if the stanza has startls" do
          before(:each) do
            @stanza.add_child(Nokogiri::XML::Node.new("starttls", @doc))
          end
          it "should send start tls" do
            @client.should_receive(:send_xml).with('<starttls xmlns="urn:ietf:params:xml:ns:xmpp-tls"/>')
            @client.receive_stanza(@stanza)
          end
        end
        
        describe "if the stanza has mechanisms" do
          before(:each) do
            mechanisms = Nokogiri::XML::Node.new("mechanisms", @doc)
            mechanism = Nokogiri::XML::Node.new("mechanism", @doc)
            mechanism.content = "PLAIN"
            mechanisms.add_child(mechanism)
            @stanza.add_child(mechanisms)
          end
                    
          it "should send authentication" do
            @client.should_receive(:send_xml).with("<auth mechanism=\"PLAIN\" xmlns=\"urn:ietf:params:xml:ns:xmpp-sasl\">amlkQHNlcnZlci50bGQAamlkAHBhc3N3b3Jk</auth>")
            @client.receive_stanza(@stanza)
          end
        end
        
      end
    end
    
    describe "when wait_for_success" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_success)
      end
      describe "when stanza is success" do
        before(:each) do
          @stanza = Nokogiri::XML::Node.new("success", @doc)
        end
        
        it "should reset the parser" do
          @client.instance_variable_get("@parser").should_receive(:reset)
          @client.receive_stanza(@stanza)
        end
        
        it "should send stream_stanza" do
          @client.should_receive(:send_xml).with("<?xml version=\"1.0\"?>\n<stream:stream xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\" to=\"server.tld\" version=\"1.0\">\n  ")
          @client.receive_stanza(@stanza)
        end
        
        it "should change state to wait_for_stream_authenticated" do
          @client.receive_stanza(@stanza)
          @client.instance_variable_get("@state").should == :wait_for_stream_authenticated
        end
        
      end
      describe "when stanza is failure" do
        before(:each) do
          @stanza = Nokogiri::XML::Node.new("failure", @doc)
        end
        it "should raise AuthenticationError if stanza has bad-auth" do
          @stanza.add_child(Nokogiri::XML::Node.new("bad-auth", @doc))
          lambda {
            @client.receive_stanza(@stanza)
          }.should raise_error(Skates::AuthenticationError)
        end
        
        it "should raise AuthenticationError if stanza has not-authorized" do
          @stanza.add_child(Nokogiri::XML::Node.new("not-authorized", @doc))
          lambda {
            @client.receive_stanza(@stanza)
          }.should raise_error(Skates::AuthenticationError)
        end
      end
    end
    
    describe "when wait_for_bind" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_bind)
      end
      
      describe "if stanza is features" do
        before(:each) do
          @stanza = Nokogiri::XML::Node.new("features", @doc)
        end
        
        describe "if stanza has bind" do
          before(:each) do
            bind = Nokogiri::XML::Node.new("bind", @doc)
            @stanza.add_child(bind)
          end
          
          it "should send_xml with the bind iq" do
            @client.should_receive(:binding_iq_id).twice.and_return(123)
            @client.should_receive(:send_xml).with("<iq type=\"set\" id=\"123\">\n  <bind xmlns=\"urn:ietf:params:xml:ns:xmpp-bind\">\n    <resource>skates_client_123</resource>\n  </bind>\n</iq>")
            @client.receive_stanza(@stanza)
          end
          
          it "should set the state to :wait_for_confirmed_binding" do
            @client.receive_stanza(@stanza)
            @client.instance_variable_get("@state").should == :wait_for_confirmed_binding
          end
        end
      end
    end
    
    describe "when wait_for_confirmed_binding" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_confirmed_binding)
      end
      describe "if stanza is iq with type=result and the righ binding_iq_id" do
        before(:each) do
          binding_iq_id = 123
          @stanza = Nokogiri::XML::Node.new("iq", @doc)
          @stanza["type"] = "result"
          @stanza["id"] = binding_iq_id.to_s
          @client.stub!(:binding_iq_id).and_return(binding_iq_id)
        end
        
          it "should send_xml with the session iq" do
            @client.should_receive(:session_iq_id).and_return(123)
            @client.should_receive(:send_xml).with("<iq type=\"set\" id=\"123\">\n  <session xmlns=\"urn:ietf:params:xml:ns:xmpp-session\"/>\n</iq>")
            @client.receive_stanza(@stanza)
          end
          
          it "should set the state to :wait_for_confirmed_session" do
            @client.receive_stanza(@stanza)
            @client.instance_variable_get("@state").should == :wait_for_confirmed_session
          end
      end
      
    end
    
    describe "when wait_for_confirmed_session" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_confirmed_session)
      end
      
      describe "if stanza is iq with type=result and the righ session_iq_id" do
        before(:each) do
          session_iq_id = 123
          @stanza = Nokogiri::XML::Node.new("iq", @doc)
          @stanza["type"] = "result"
          @stanza["id"] = session_iq_id.to_s
          @client.stub!(:session_iq_id).and_return(session_iq_id)
        end
        
        it "should send_xml the initial presence" do
          @client.should_receive(:send_xml).with("<presence/>")
          @client.receive_stanza(@stanza)
        end
        
        it "should set the state to :connected" do
          @client.receive_stanza(@stanza)
          @client.instance_variable_get("@state").should == :connected
        end
      end
    end
    
    describe "when wait_for_proceed" do
      before(:each) do
        @client.instance_variable_set("@state", :wait_for_proceed)
        @client.stub!(:start_tls).and_return(true)
      end
      
      it "should start_tls" do
        @client.should_receive(:start_tls)
        @client.receive_stanza(@stanza)
      end
      
      it "reset the parser" do
        @client.instance_variable_get("@parser").should_receive(:reset)
        @client.receive_stanza(@stanza)        
      end
      
      it "should set the state to :wait_for_stream" do
        @client.receive_stanza(@stanza)
        @client.instance_variable_get("@state").should == :wait_for_stream
      end
      
      it "should send the stream stanza" do
        @client.should_receive(:send_xml).with("<?xml version=\"1.0\"?>\n<stream:stream xmlns=\"jabber:client\" xmlns:stream=\"http://etherx.jabber.org/streams\" to=\"server.tld\" version=\"1.0\">\n  ")
        @client.receive_stanza(@stanza)
      end 
    end 
  end 
  
  describe "stream_namespace" do
    it "should return jabber:client" do
      @client.stream_namespace.should == "jabber:client"
    end
  end
  
end
