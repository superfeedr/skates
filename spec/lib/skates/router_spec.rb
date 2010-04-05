require File.dirname(__FILE__) + '/../../spec_helper'

describe Skates::Route do
  before(:each) do
    @controller = "bar"
    @action     = "bar"
    @xpath     = "//message"
    Kernel.stub!(:const_get).with("#{@controller.capitalize}Controller")
  end

  describe ".initialize" do
    it "should raise an exception if no controller is specified" do
      lambda { Skates::Route.new("action" => @action, "xpath" => @xpath) }.should raise_error(/controller/)
    end
    it "should raise an exception if no action is specified" do
      lambda { Skates::Route.new("controller" => @controller, "xpath" => @xpath) }.should raise_error(/action/)
    end
    it "should raise an exception if no xpath is specified" do
      lambda { Skates::Route.new("action" => @action, "controller" => @controller) }.should raise_error(/xpath/)
    end
  end

  describe ".accepts?" do
    it "should check the stanza with Xpath" do
      mock_stanza = mock(Object)
      route = Skates::Route.new("controller" => "bar", "action" => "bar", "xpath" => ["//message", {}])
      mock_stanza.should_receive(:xpath).with("//message", {}).and_return([])
      route.accepts?(mock_stanza)
    end
  end
end


describe Skates::StanzaRouter do 

  before(:each) do
    @router = Skates::StanzaRouter.new
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
        @router.routes << mock(Skates::Route, :accepts? => false)
      end
    end

    context "when the before_route callback is defined" do
      before(:each) do
        @proc = Proc.new { |stanza|  
        }
        @router.before_route(&@proc)
      end
      
      it "should call the callback" do
        @proc.should_receive(:call).with(@xml)
        @router.route(@xml)
      end
      
      context "when the callback returns true" do
        before(:each) do
          @proc = Proc.new { |stanza| 
            true 
          }
          @router.before_route(&@proc)
        end
        
        it "should not even check if a route accepts this stanza" do
          @router.routes.each do |r|
            r.should_not_receive(:accepts?).with(@xml)
          end
          @router.route(@xml)
        end
      end
      
      context "when the callback returns false" do
        before(:each) do
          @proc = Proc.new { |stanza| 
            false 
          }
          @router.before_route(&@proc)
        end
        
        it "should check if a route accepts this stanza" do
          @router.routes.each do |r|
            r.should_receive(:accepts?).with(@xml)
          end
          @router.route(@xml)
        end
      end
      
      context "when the callback raises an error" do
        before(:each) do
          @proc = Proc.new { |stanza| 
            raise 
          }
          @router.before_route(&@proc)
        end
        
        it "should check if a route accepts this stanza" do
          @router.routes.each do |r|
            r.should_receive(:accepts?).with(@xml)
          end
          @router.route(@xml)
        end
      end
      
    end
    
    context "when the before_route callback is not defined" do
      it "should check each routes to see if they match the stanza and take the first of the matching" do
        @router.routes.each do |r|
          r.should_receive(:accepts?).with(@xml)
        end
        @router.route(@xml)
      end
    
      context "if one route is found" do 
        before(:each) do
          @accepting_route = mock(Skates::Route, :accepts? => true, :action => "action", :controller => "controller", :xpath => "xpath")
          @router.routes << @accepting_route
        end

        it "should call execute_route" do
          @router.should_receive(:execute_route).with(@accepting_route.controller, @accepting_route.action, @xml)
          @router.route(@xml)
        end
      end

      context "if no route matches the stanza" do
        it "should return false" do
          @router.route(@xml).should be_false
        end
      end
    end
  end

  describe "execute_route" do
    before(:each) do
      @action = "action"
      @controller = Skates::Base::Controller
      @xml = mock(Nokogiri::XML::Node)
      @mock_stanza = mock(Skates::Base::Stanza)
      @mock_controller = mock(Skates::Base::Controller, {:new => true, :evaluate => "hello world"})
      Kernel.stub!(:const_get).with(@action.capitalize).and_return(Skates::Base::Stanza) 
      Skates::Base::Stanza.stub!(:new).with(@xml).and_return(@mock_stanza)
      @connection = mock(Skates::XmppConnection, :send_xml => true)
      @router.stub!(:connection).and_return(@connection)
      @controller.stub!(:new).and_return(@mock_controller)
      @mock_controller.stub!(:perform).with(@action)
    end

    describe "when the Stanza class exists" do
      it "should instantiate the route's stanza " do
        Kernel.should_receive(:const_get).with(@action.capitalize).and_return(Skates::Base::Stanza) 
        Skates::Base::Stanza.should_receive(:new).with(@xml).and_return(@mock_stanza)
        @router.execute_route(@controller, @action, @xml)
      end
      
      it "should instantiate the route's controller" do
        @controller.should_receive(:new).with(@mock_stanza).and_return(@mock_controller)
        @router.execute_route(@controller, @action, @xml)
      end
    end
    
    describe "when the stanza class doesn't exist" do
      it "should instantiate the route's controller with the xml" do
        Kernel.should_receive(:const_get).with(@action.capitalize).and_raise(NameError) 
        @controller.should_receive(:new).with(@xml).and_return(@mock_controller)
        @router.execute_route(@controller, @action, @xml)
      end
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
      @router.instance_variable_set("@routes", [mock(Skates::Route), mock(Skates::Route)])
      @router.purge_routes!
      @router.routes.should == []
    end
  end
  
  describe "draw" do
    before(:each) do
      @dsl = Skates::Router::DSL.new 
      Skates::Router::DSL.stub!(:new).and_return(@dsl) 
      @routes = [mock(Skates::Route, :is_a? => true), mock(Skates::Route, :is_a? => true), mock(Skates::Route, :is_a? => true)]
      @router.stub!(:sort)
      @dsl.stub!(:routes).and_return(@routes)
    end
    
    it "shoudl instantiate a new DSL" do
      Skates::Router::DSL.should_receive(:new).and_return(@dsl) 
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
      @dsl.should_receive(:routes).and_return([mock(Skates::Route, :is_a? => false)])
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