require File.dirname(__FILE__) + '/../../spec_helper'

describe Babylon::Route do
  before(:each) do
    @controller = "bar"
    @action     = "bar"
    @xpath     = "//message"
    Kernel.stub!(:const_get).with("#{@controller.capitalize}Controller")
  end

  describe ".initialize" do
    it "should raise an exception if no controller is specified" do
      lambda { Babylon::Route.new("action" => @action, "xpath" => @xpath) }.should raise_error(/controller/)
    end
    it "should raise an exception if no action is specified" do
      lambda { Babylon::Route.new("controller" => @controller, "xpath" => @xpath) }.should raise_error(/action/)
    end
    it "should raise an exception if no xpath is specified" do
      lambda { Babylon::Route.new("action" => @action, "controller" => @controller) }.should raise_error(/xpath/)
    end
  end

  describe ".accepts?" do
    it "should check the stanza with Xpath" do
      mock_stanza = mock(Object)
      route = Babylon::Route.new("controller" => "bar", "action" => "bar", "xpath" => "//message")
      route.router = mock(Babylon::Router, :namespaces => [])
      mock_stanza.should_receive(:xpath).with(route.xpath, route.router.namespaces).and_return([])
      route.accepts?(mock_stanza)
    end
  end
end


describe Babylon::StanzaRouter do 

  before(:each) do
    @router = Babylon::StanzaRouter.new
  end

  describe "initialize" do
    it "should have an empty array as routes" do
      @router.routes.should == []
    end
  end

  describe "connected" do
    it "should set the connection" do
      connection = mock(Object)
      @router.connected(connection)
      @router.connection.should == connection
    end
  end

  describe "route" do
    before(:each) do
      @xml = mock(Nokogiri::XML::Node)
      3.times do |t|
        @router.routes << mock(Babylon::Route, :accepts? => false)
      end
    end

    it "should check each routes to see if they match the stanza and take the first of the matching" do
      @router.routes.each do |r|
        r.should_receive(:accepts?).with(@xml)
      end
      @router.route(@xml)
    end

    describe "if one route is found" do 
      before(:each) do
        @accepting_route = mock(Babylon::Route, :accepts? => true, :action => "action", :controller => "controller", :xpath => "xpath")
        @router.routes << @accepting_route
      end

      it "should call execute_route" do
        @router.should_receive(:execute_route).with(@accepting_route.controller, @accepting_route.action, @xml)
        @router.route(@xml)
      end
    end

    describe "if no route matches the stanza" do
      it "should return false" do
        @router.route(@xml).should be_false
      end
    end

  end

  describe "execute_route" do
    before(:each) do
      @action = "action"
      @controller = Babylon::Base::Controller
      @xml = mock(Nokogiri::XML::Node)
      @mock_stanza = mock(Babylon::Base::Stanza)
      @mock_controller = mock(Babylon::Base::Controller, {:new => true, :evaluate => "hello world"})
      Kernel.stub!(:const_get).with(@action.capitalize).and_return(Babylon::Base::Stanza) 
      Babylon::Base::Stanza.stub!(:new).with(@xml).and_return(@mock_stanza)
      @connection = mock(Babylon::XmppConnection, :send_xml => true)
      @router.stub!(:connection).and_return(@connection)
      @controller.stub!(:new).and_return(@mock_controller)
      @mock_controller.stub!(:perform).with(@action)
    end

    it "should instantiate the route's stanza" do
      Kernel.should_receive(:const_get).with(@action.capitalize).and_return(Babylon::Base::Stanza) 
      Babylon::Base::Stanza.should_receive(:new).with(@xml).and_return(@mock_stanza)
      @router.execute_route(@controller, @action, @xml)
    end

    it "should instantiate the route's controller" do
      @controller.should_receive(:new).and_return(@mock_controller)
      @router.execute_route(@controller, @action, @xml)
    end

    it "should call perform on the controller with the action's name" do
      @mock_controller.should_receive(:perform).with(@action)
      @router.execute_route(@controller, @action, @xml)
    end
    
    it "should send the controller's response to the connection" do
      @connection.should_receive(:send_xml).with(@mock_controller.evaluate)
      @router.execute_route(@controller, @action, @xml)
    end
  end

  describe "purge_routes!" do
    it "should delete all routes" do
      @router.instance_variable_set("@routes", [mock(Babylon::Route), mock(Babylon::Route)])
      @router.purge_routes!
      @router.routes.should == []
    end
  end
  
  describe "draw" do
    before(:each) do
      @dsl = Babylon::Router::DSL.new 
      Babylon::Router::DSL.stub!(:new).and_return(@dsl) 
      @routes = [mock(Babylon::Route, :is_a? => true, :router= => true), mock(Babylon::Route, :is_a? => true, :router= => true), mock(Babylon::Route, :is_a? => true, :router= => true)]
      @router.stub!(:sort)
      @dsl.stub!(:routes).and_return(@routes)
    end
    
    it "shoudl instantiate a new DSL" do
      Babylon::Router::DSL.should_receive(:new).and_return(@dsl) 
      @router.draw {}
    end
    
    it "should instance_eval the block" do
      block = Proc.new {}
      @dsl.should_receive(:instance_eval).with(&block)
      @router.draw &block
    end
    
    it "should check that each route is a Route" do
      @dsl.should_receive(:routes).twice.and_return(@routes)
      @router.draw {}
    end
    
    it "should raise an error if one of the routes is not valid" do
      @dsl.should_receive(:routes).and_return([mock(Babylon::Route, :is_a? => false)])
      lambda {
        @router.draw {}
      }.should raise_error()
    end
    
    it "should assign the dsl routes as @routes" do
      @dsl.should_receive(:routes).twice.and_return(@routes)
      @router.draw {}
      @router.routes.should == @routes
    end
    
    it "should sort the routes" do
      @router.should_receive(:sort)
      @router.draw {}
    end
    
  end

end