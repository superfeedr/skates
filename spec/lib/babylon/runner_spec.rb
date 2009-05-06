require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + '/../../em_mock'
require "fileutils"

describe Babylon::Runner do 

  before(:all) do
    FileUtils.chdir("#{FileUtils.pwd}/templates/babylon")  unless ("#{FileUtils.pwd}" =~ /\/templates\/babylon/ )
  end

  describe ".prepare" do

    before(:each) do
      @stub_config_file = File.open("config/config.yaml")
      @stub_config_content = File.read("config/config.yaml")
      File.stub!(:open).with('config/config.yaml').and_return(@stub_config_file)
      Babylon::Runner.stub!(:require_directory).and_return(true)
    end

    it "should add the environment log file as an outputter to babylon's default log" do
      @logger = Log4r::FileOutputter.new("#{Babylon.environment}", :filename => "log/#{Babylon.environment}.log", :trunc => false)
      Log4r::FileOutputter.should_receive(:new).with("test", :filename => "log/test.log", :trunc => false).and_return(@logger)
      Babylon.logger.should_receive(:add).with(@logger)
      Babylon::Runner.prepare("test")
    end

    it "should require all models" do
      Babylon::Runner.should_receive(:require_directory).with('app/models/*.rb').and_return(true)
      Babylon::Runner.prepare("test")
    end

    it "should require all stanzas" do
      Babylon::Runner.should_receive(:require_directory).with('app/stanzas/*.rb').and_return(true)
      Babylon::Runner.prepare("test")
    end

    it "should require all controllers" do
      Babylon::Runner.should_receive(:require_directory).with('app/controllers/*_controller.rb').and_return(true)
      Babylon::Runner.prepare("test")
    end

    it "should create a router" do
      router = Babylon::StanzaRouter.new
      Babylon::StanzaRouter.should_receive(:new).and_return(router)
      Babylon.should_receive(:router=).with(router) 
      Babylon::Runner.prepare("test")
    end

    it "should load the routes" do
      Babylon::Runner.should_receive(:require).with('config/routes.rb')
      Babylon::Runner.prepare("test")
    end

    it "should load the configuration file" do
      File.should_receive(:open).with('config/config.yaml').and_return(@stub_config_file)
      Babylon::Runner.prepare("test")
    end

    it "should assign the configuration" do
      Babylon::Runner.prepare("test")
      Babylon.config.should == YAML.load(@stub_config_content)["test"]
    end

    it "should cache the views" do
      Babylon.should_receive(:cache_views)
      Babylon::Runner.prepare("test")
    end
  end

  describe "require_directory" do
    before(:each) do
      @dir = "/my/dir"
      @files = ["hello.rb", "byebye.rb"]
      Dir.stub!(:glob).with(@dir).and_return(@files)
      @files.each do |f|
        Babylon::Runner.stub!(:require).with(f).and_return(true)
      end
    end
    it "should list all files in the directory" do
      Dir.should_receive(:glob).with(@dir).and_return(@files)
      Babylon::Runner.require_directory(@dir)
    end
    it "should require each of the files" do
      @files.each do |f|
        Babylon::Runner.should_receive(:require).with(f).and_return(true)
      end
      Babylon::Runner.require_directory(@dir)      
    end
  end

  describe ".run" do

    before(:each) do
      Babylon::ClientConnection.stub!(:connect).and_return(true)
      Babylon::ComponentConnection.stub!(:connect).and_return(true)
      EventMachine.stub!(:run).and_yield
    end

    it "should set the environment" do
      Babylon::Runner.run("test")
      Babylon.environment.should == "test" 
    end

    it "should epoll the EventMachine" do
      EventMachine.should_receive(:epoll)
      Babylon::Runner.run("test") 
    end

    it "should run the EventMachine" do
      EventMachine.should_receive(:run)
      Babylon::Runner.run("test") 
    end

    it "should call prepare" do
      Babylon::Runner.should_receive(:prepare).with("test")
      Babylon::Runner.run("test") 
    end

    it "should connect the client connection if specified by the config" do
      Babylon.stub!(:config).and_return({"application_type" => "client"})
      Babylon::ClientConnection.should_receive(:connect).with(Babylon.config, Babylon::Runner)
      Babylon::Runner.run("test") 
    end

    it "should connect the component connection if no application_type specified by the config" do
      Babylon.stub!(:config).and_return({})
      Babylon::ComponentConnection.should_receive(:connect).with(Babylon.config, Babylon::Runner)
      Babylon::Runner.run("test") 
    end

  end

  describe ".connection_observers" do
    it "should return an array" do
      Babylon::Runner.connection_observers.should be_an_instance_of(Array)
    end
  end

  describe ".add_connection_observer" do
    before(:each) do
      class MyController < Babylon::Base::Controller; end
    end

    it "should not accept non-Babylon::Base::Controller subclasses" do
      Babylon::Runner.add_connection_observer(Object).should be_false
    end

    it "should accept" do
      Babylon::Runner.add_connection_observer(MyController).should be_true
    end

    it "should add it to the list of observers" do
      observers = Babylon::Runner.connection_observers
      Babylon::Runner.add_connection_observer(MyController)
      observers.include?(MyController).should be_true
    end

    it "should not add it twice" do
      observers = Babylon::Runner.connection_observers
      Babylon::Runner.add_connection_observer(MyController)
      Babylon::Runner.add_connection_observer(MyController)
      observers.should == [MyController]
    end

  end

  describe ".on_connected" do
    before(:each) do
      @connection = mock(Object)
      Babylon.router = Babylon::StanzaRouter.new
      Babylon.router.stub!(:connected).with(@connection)
    end

    it "should call connected on StanzaRouter" do
      Babylon.router.should_receive(:connected).with(@connection)
      Babylon::Runner.on_connected(@connection)
    end

    it "should call on_connected on the various observers and send the corresponding response" do
      Babylon::Runner.add_connection_observer(MyController)
      Babylon.router.should_receive(:execute_route).with(MyController, "on_connected")
      Babylon::Runner.on_connected(@connection)
    end
  end

  describe ".on_disconnected" do
    it "should stop the event loop" do
      connection = mock(Object)
      EventMachine.should_receive(:stop_event_loop)
      Babylon::Runner.on_disconnected()
    end

    it "should call on_disconnected on the various observers" do
      class MyObserver < Babylon::Base::Controller
        def on_disconnected
        end
      end
      my_observer = MyObserver.new
      Babylon::Runner.add_connection_observer(MyObserver)
      MyObserver.should_receive(:new).and_return(my_observer)
      my_observer.should_receive(:on_disconnected)
      Babylon::Runner.on_disconnected
    end
  end

  describe ".on_stanza" do
    it "should call route on StanzaRouter" do
      stanza = mock(Object)
      Babylon.router.should_receive(:route).with(stanza)
      Babylon::Runner.on_stanza(stanza)
    end
  end
end
