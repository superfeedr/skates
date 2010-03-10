require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../em_mock'

describe Skates::Runner do 
  before(:all) do
    FileUtils.chdir("#{FileUtils.pwd}/templates/skates")  unless ("#{FileUtils.pwd}" =~ /\/templates\/skates/ )
  end
  
  describe ".prepare" do
    before(:each) do
      @stub_config_file = File.open("config/config.yaml")
      @stub_config_content = File.read("config/config.yaml")
      File.stub!(:open).with('config/config.yaml').and_return(@stub_config_file)
      Skates::Runner.stub!(:require_directory).and_return(true)
    end

    it "should add the environment log file as an outputter to skates's default log" do
      Skates.should_receive(:reopen_logs)  
      Skates::Runner.prepare("test")
    end

    it "should require all models" do
      Skates::Runner.should_receive(:require_directory).with('app/models/*.rb').and_return(true)
      Skates::Runner.prepare("test")
    end

    it "should require all stanzas" do
      Skates::Runner.should_receive(:require_directory).with('app/stanzas/*.rb').and_return(true)
      Skates::Runner.prepare("test")
    end

    it "should require all controllers" do
      Skates::Runner.should_receive(:require_directory).with('app/controllers/*_controller.rb').and_return(true)
      Skates::Runner.prepare("test")
    end

    it "should create a router" do
      router = Skates::StanzaRouter.new
      Skates::StanzaRouter.should_receive(:new).and_return(router)
      Skates.should_receive(:router=).with(router) 
      Skates::Runner.prepare("test")
    end

    it "should load the routes" do
      Skates::Runner.should_receive(:require).with('config/routes.rb')
      Skates::Runner.prepare("test")
    end

    it "should load the configuration file" do
      File.should_receive(:open).with('config/config.yaml').and_return(@stub_config_file)
      Skates::Runner.prepare("test")
    end

    it "should assign the configuration" do
      Skates::Runner.prepare("test")
      Skates.config.should == YAML.load(@stub_config_content)["test"]
    end

    it "should cache the views" do
      Skates.should_receive(:cache_views)
      Skates::Runner.prepare("test")
    end
  end

  describe "require_directory" do
    before(:each) do
      @dir = "/my/dir"
      @files = ["hello.rb", "byebye.rb"]
      Dir.stub!(:glob).with(@dir).and_return(@files)
      @files.each do |f|
        Skates::Runner.stub!(:require).with(f).and_return(true)
      end
    end
    it "should list all files in the directory" do
      Dir.should_receive(:glob).with(@dir).and_return(@files)
      Skates::Runner.require_directory(@dir)
    end
    it "should require each of the files" do
      @files.each do |f|
        Skates::Runner.should_receive(:require).with(f).and_return(true)
      end
      Skates::Runner.require_directory(@dir)      
    end
  end

  describe ".run" do
    before(:each) do
      Skates::ClientConnection.stub!(:connect).and_return(true)
      Skates::ComponentConnection.stub!(:connect).and_return(true)
      EventMachine.stub!(:run).and_yield
    end

    it "should set the environment" do
      Skates::Runner.run("test")
      Skates.environment.should == "test" 
    end

    it "should epoll the EventMachine" do
      EventMachine.should_receive(:epoll)
      Skates::Runner.run("test") 
    end

    it "should run the EventMachine" do
      EventMachine.should_receive(:run)
      Skates::Runner.run("test") 
    end

    it "should call prepare" do
      Skates::Runner.should_receive(:prepare).with("test")
      Skates::Runner.run("test") 
    end

    it "should connect the client connection if specified by the config" do
      Skates.stub!(:config).and_return({"application_type" => "client"})
      Skates::ClientConnection.should_receive(:connect).with(Skates.config, Skates::Runner)
      Skates::Runner.run("test") 
    end

    it "should connect the component connection if no application_type specified by the config" do
      Skates.stub!(:config).and_return({})
      Skates::ComponentConnection.should_receive(:connect).with(Skates.config, Skates::Runner)
      Skates::Runner.run("test") 
    end

  end

  describe ".connection_observers" do
    it "should return an array" do
      Skates::Runner.connection_observers.should be_an_instance_of(Array)
    end
  end

  describe ".add_connection_observer" do
    before(:each) do
      class MyController < Skates::Base::Controller; end
    end

    it "should not accept non-Skates::Base::Controller subclasses" do
      Skates::Runner.add_connection_observer(Object).should be_false
    end

    it "should accept" do
      Skates::Runner.add_connection_observer(MyController).should be_true
    end

    it "should add it to the list of observers" do
      observers = Skates::Runner.connection_observers
      Skates::Runner.add_connection_observer(MyController)
      observers.include?(MyController).should be_true
    end

    it "should not add it twice" do
      observers = Skates::Runner.connection_observers
      Skates::Runner.add_connection_observer(MyController)
      Skates::Runner.add_connection_observer(MyController)
      observers.should == [MyController]
    end

  end

  describe ".on_connected" do
    before(:each) do
      @connection = mock(Object)
      Skates.router = Skates::StanzaRouter.new
      Skates.router.stub!(:connected).with(@connection)
      Skates.router.stub!(:execute_route).with(MyController, "on_connected")
    end

    it "should call connected on StanzaRouter" do
      Skates.router.should_receive(:connected).with(@connection)
      Skates::Runner.on_connected(@connection)
    end

    it "should call on_connected on the various observers and send the corresponding response" do
      Skates::Runner.add_connection_observer(MyController)
      Skates.router.should_receive(:execute_route).with(MyController, "on_connected")
      Skates::Runner.on_connected(@connection)
    end
  end

  describe ".on_disconnected" do
    it "should call on_disconnected on the various observers" do
      class MyObserver < Skates::Base::Controller; def on_disconnected; end; end
      my_observer = MyObserver.new
      Skates::Runner.add_connection_observer(MyObserver)
      MyObserver.should_receive(:new).and_return(my_observer)
      my_observer.should_receive(:on_disconnected)
      Skates::Runner.on_disconnected
    end
    
    context "when the application should auto-reconnect" do
      before(:each) do
        Skates.config["auto-reconnect"] = true
        EventMachine.stub!(:reactor_running?).and_return(false)
        EventMachine.stub!(:add_timer).and_yield()
        @delay = 15
        Skates::Runner.stub!(:fib).and_return(@delay)
      end
      
      it "should determine when is the best time to reconnect with fibonacci" do
        Skates::Runner.should_receive(:fib).and_return(@delay)
        Skates::Runner.on_disconnected()
      end
      
      it "should try to reconnect at the determined time" do
        EventMachine.stub!(:reactor_running?).and_return(true)
        Skates::Runner.should_receive(:reconnect)
        EventMachine.should_receive(:add_timer).with(@delay).and_yield()
        Skates::Runner.on_disconnected()
      end
    end
    
    context "when the application should not auto-reconnect" do
      before(:each) do
        Skates.config["auto-reconnect"] = false
      end
      
      it "should stop the event loop" do
        connection = mock(Object)
        EventMachine.should_receive(:stop_event_loop)
        Skates::Runner.on_disconnected()
      end
    end
  end

  describe ".on_stanza" do
    it "should call route on StanzaRouter" do
      stanza = mock(Object)
      Skates.router.should_receive(:route).with(stanza)
      Skates::Runner.on_stanza(stanza)
    end
  end
end
