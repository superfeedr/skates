require File.dirname(__FILE__) + '/../../spec_helper'

describe Babylon::Route do
  
  it "should raise an exception if no controller is specified" do
    lambda { Babylon::Route.new("action" => "bar") }.should raise_error(/controller/)
  end

  it "should raise an exception if no action is specified" do
    lambda { Babylon::Route.new("controller" => "bar") }.should raise_error(/action/)
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
    it "should return false if not connected" do
      @router.connected(false)
      @router.route(@xml).should be_false
    end
    
    describe "when connected" do
      before(:each) do
        @connection = mock(Babylon::XmppConnection, :send_xml => true)
        @router.connected(@connection)
      end
    
      it "should check each routes to see if they match the stanza and take the first of the matching" do
        @router.routes.each do |r|
          r.should_receive(:accepts?).with(@xml)
        end
        @router.route(@xml)
      end
    
      describe "if one route is found" do 
        before(:each) do
          @accepting_route = mock(Babylon::Route, :accepts? => true)
          @accepting_route.should_receive(:accepts?).and_return(true)
          @accepting_route.stub!(:action).and_return("action")
          @mock_controller = mock(Babylon::Base::Controller.new, :response => mock(Nokogiri::XML::Document))
          @mock_controller_class = mock(Class, :new => @mock_controller)
          @accepting_route.stub!(:controller).and_return(@mock_controller_class)
          @mock_stanza = mock(Babylon::Base::Stanza)
          @router.routes << @accepting_route
        end
        
        it "should instantiate the route's stanza" do
          Kernel.should_receive(:const_get).with(@accepting_route.action.capitalize).and_return(Babylon::Base::Stanza) 
          Babylon::Base::Stanza.should_receive(:new).with(@xml).and_return(@mock_stanza)
          @router.route(@xml)
        end
        
        it "should instantiate the route's controller" do
          @mock_controller_class.should_receive(:new).and_return(@mock_controller)
          @router.route(@xml)
        end
        
        it "should call perform on the controller with the action's name" do
          @mock_controller.should_receive(:perform).with(@accepting_route.action)
          @router.route(@xml)
        end
        
        it "should send the controller's response to the connection" do
          @connection.should_receive(:send_xml).with(@mock_controller.response)
          @router.route(@xml)
        end
        
      end
      
      describe "if no route matches the stanza" do
        it "should return false" do
          @router.route(@xml).should be_false
        end
      end
    end
  end
  
end