require File.dirname(__FILE__) + '/../../spec_helper'
require "fileutils"

describe Babylon::Runner do
  before(:all) do
    FileUtils.chdir("#{FileUtils.pwd}/templates/babylon")  unless ("#{FileUtils.pwd}" =~ /\/templates\/babylon/ )
  end

  def client_mock
    @client_mock ||= 
    begin
      mock(Babylon::ClientConnection)
    end
  end

  def component_mock
    @client_mock ||= 
    begin
      mock(Babylon::ComponentConnection)
    end
  end

  describe ".on_connected" do
    it "should call connected on CentralRouter" do
      connection = mock(Object)
      Babylon::CentralRouter.should_receive(:connected).with(connection)
      Babylon::Runner.on_connected(connection)
    end
    
    it "should call on_connected on the various observers" do
      class MyObserver
        def on_connected(connection)
        end
      end
      my_observer = MyObserver.new
      Babylon::Runner.add_connection_observer(my_observer)
      connection = mock(Object)
      my_observer.should_receive(:on_connected).with(connection)
      Babylon::Runner.on_connected(connection)
    end
    
  end

  describe ".on_disconnected" do
    it "should stop the event loop" do
      connection = mock(Object)
      EventMachine.should_receive(:stop_event_loop)
      Babylon::Runner.on_disconnected()
    end
    
    it "should call on_disconnected on the various observers" do
      class MyObserver
        def on_disconnected
        end
      end
      my_observer = MyObserver.new
      Babylon::Runner.add_connection_observer(my_observer)
      my_observer.should_receive(:on_disconnected)
      Babylon::Runner.on_disconnected
    end
  end

  describe ".on_stanza" do
    it "should call route on CentralRouter" do
      stanza = mock(Object)
      Babylon::CentralRouter.should_receive(:route).with(stanza)
      Babylon::Runner.on_stanza(stanza)
    end
  end

  describe ".run" do

    before(:each) do
      @stub_config_file = File.open("config/config.yaml")
      @config = YAML.load(@stub_config_file)
      YAML.stub!(:load).with(@stub_config_file).and_return(@config)
      File.stub!(:open).with('config/config.yaml').and_return(@stub_config_file)
      EventMachine.stub!(:run).and_yield
      @client_connection_params = @config["test"]
      Babylon::ClientConnection.stub!(:connect).with(@client_connection_params, Babylon::Runner).and_return(client_mock)
      Babylon::ComponentConnection.stub!(:connect).with(@client_connection_params, Babylon::Runner).and_return(component_mock)
    end

    it "should load the configuration" do
      Babylon::Runner.run("test")
      Babylon.config.should be_a(Hash)
    end

    it "should epoll the EventMachine" do
      EventMachine.should_receive(:epoll)
      Babylon::Runner.run("test")
    end

    it "should run the EventMachine" do
      EventMachine.should_receive(:run)
      Babylon::Runner.run("test")
    end

    it "should load the configuration file" do
      File.should_receive(:open).with('config/config.yaml').and_return(@stub_config_file)
      Babylon::Runner.run("test")
    end

    it "should connect the client connection if specified by the config" do
      @config["test"]["application_type"] = "client"
      Babylon::ClientConnection.should_receive(:connect).with(@client_connection_params.merge({"application_type" => "client"}), Babylon::Runner).and_return(client_mock)
      Babylon::Runner.run("test")
    end

    it "should connect the component connection if no application_type specified by the config" do
      Babylon::ComponentConnection.should_receive(:connect).with(@client_connection_params, Babylon::Runner).and_return(component_mock)
      Babylon::Runner.run("test")
    end

    it "should require all models" 

    it "should require all controllers"

    it "should require all routes"

  end

end
