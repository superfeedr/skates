require File.dirname(__FILE__) + '/../../../spec_helper'

describe Skates::Router::DSL do
  before(:each) do
    Skates.router = Skates::StanzaRouter.new
    Skates.router.purge_routes!
    class ControllerController; end
  end

  it "raises an exception if the route lacks a controller" do
    lambda { Skates.router.draw do
      xpath("/test").to(:action => "foo")
    end }.should raise_error(/controller/)
  end

  it "raises an exception if the route lacks an action" do
    lambda { Skates.router.draw do
      xpath("/test").to(:controller => "foo")
    end }.should raise_error(/action/)
  end

  it "raises an exception if the route has no destination" do
    lambda { Skates.router.draw do
      xpath("//test")
    end }.should raise_error(/destination/)
  end

  it "creates a route with the specified xpath, controller and action" do
    Skates.router.draw do
      xpath("//test"
      ).to(:controller => "controller", :action => "action")
    end
    routes = Skates.router.instance_variable_get("@routes")
    routes.length.should == 1
  end
  
  describe :disco_info do
    it "matches the root disco#info namespace" do
      Skates.router.draw do
        disco_info.to(:controller => "controller", :action => "action")
      end
      route = Skates.router.instance_variable_get("@routes").last
      route.xpath.should == "//iq[@type='get']/*[namespace(., 'query', 'http://jabber.org/protocol/disco#info')]"
    end

    it "matches the disco#info namespace for the specified node" do
      Skates.router.draw do
        disco_info("test").to(:controller => "controller", :action => "action")
      end
      route = Skates.router.instance_variable_get("@routes").last
      route.xpath.should == "//iq[@type='get']/*[namespace(., 'query', 'http://jabber.org/protocol/disco#info') and @node = 'test']"
    end
  end

  describe :disco_items do
    it "matches the root disco#items namespace" do
      Skates.router.draw do
        disco_items.to(:controller => "controller", :action => "action")
      end
      route = Skates.router.instance_variable_get("@routes").last
      route.xpath.should == "//iq[@type='get']/*[namespace(., 'query', 'http://jabber.org/protocol/disco#items')]"
    end

    it "matches the disco#items namespace for the specified node" do
      Skates.router.draw do
        disco_items("test").to(:controller => "controller", :action => "action")
      end
      route = Skates.router.instance_variable_get("@routes").last
      route.xpath.should == "//iq[@type='get']/*[namespace(., 'query', 'http://jabber.org/protocol/disco#items') and @node = 'test']"
    end
  end
end
