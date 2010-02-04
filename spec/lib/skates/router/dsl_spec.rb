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

  it "creates a route with the specified xpath, controller, action and priority" do
    Skates.router.draw do
      xpath("//test"
      ).to(:controller => "controller", :action => "action").priority(5)
    end
    routes = Skates.router.instance_variable_get("@routes")
    routes.length.should == 1
  end
  
  it "should create routes with the right namespace" do
    Skates.router.draw do
      xpath("//ns:test", {"ns" => "http://my.namespace.uri"}
      ).to(:controller => "controller", :action => "action").priority(5)
    end
    route = Skates.router.instance_variable_get("@routes").first
    route.xpath.should == ["//ns:test", {"ns"=>"http://my.namespace.uri"}]
  end
  
end
