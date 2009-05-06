require File.dirname(__FILE__) + '/../../../spec_helper'

describe Babylon::Base::Controller do

  before(:each) do
    Babylon.views.stub!(:[]).and_return("") # Stubbing read for view
  end
  
  describe ".initialize" do
    before(:each) do
      @params = {:a => "a", :b => 1, :c => {:key => "value"}, :stanza => "<hello>world</hello>"}    
    end
    
    it "should have a stanza instance" do
      stanza = mock(Object)
      c = Babylon::Base::Controller.new(stanza)
      
      c.instance_variables.should be_include "@stanza"
      c.instance_variable_get("@stanza").should == stanza
    end
    
    it "should not be rendered yet" do
      c = Babylon::Base::Controller.new(@params)
      c.rendered.should_not be_true
    end
  end
  
  describe ".perform" do
    before(:each) do
      @action = :subscribe
      params = {:stanza => "<hello>world</hello>"}
      @controller = Babylon::Base::Controller.new(params)
      @controller.class.send(:define_method, @action) do # Defining the action method
        # Do something
      end
    end
    
    it "should setup the action to the param" do
      @controller.perform(@action) do
        # Do something
      end
      @controller.instance_variable_get("@action_name").should == @action
    end
    
    it "should call the action" do
      @controller.should_receive(:send).with(@action).and_return()
      @controller.perform(@action) do
        # Do something
      end
    end
    
    it "should write an error to the log in case of failure of the action" do
      @controller.stub!(:send).with(@action).and_raise(StandardError)
      Babylon.logger.should_receive(:error)
      @controller.perform(@action) do
        # Do something
      end
    end
    
    it "should call render" do
      @controller.should_receive(:render)
      @controller.perform(@action) do
        # Do something
      end
    end
  end
  
  describe ".render" do
    before(:each) do
      @controller = Babylon::Base::Controller.new({})
      @controller.action_name = :subscribe
    end
    
    it "should assign a value to view" do
      @controller.render
      @controller.instance_variable_get("@view").should_not be_nil
    end
    
    describe "with :nothing option" do
      it "should not render any file" do
        @controller.should_not_receive(:render_for_file)
        @controller.render :nothing => true
      end
    end
    
    describe "with no option" do
      it "should call render with default_file_name if no option is provided" do
        @controller.should_receive(:default_template_name)
        @controller.render      
      end
    end
    
    describe " with an :action option" do
      it "should call render with the file name corresponding to the action given as option" do
        action = :unsubscribe
        @controller.should_receive(:default_template_name).with("#{action}")
        @controller.render(:action => action)
      end
    end
    
    describe " with a file option" do
      it "should call render_for_file with the correct path if an option file is provided" do
        file = "myfile"
        @controller.should_receive(:render_for_file)
        @controller.render(:file => file)
      end
    end
    
    it "should render twice when called twice" do
      @controller.render
      @controller.should_not_receive(:render_for_file)
      @controller.render      
    end
  end

  describe ".assigns" do
    
    before(:each) do
      @stanza = mock(Babylon::Base::Stanza)
      @controller = Babylon::Base::Controller.new(@stanza)
    end
    
    it "should be a hash" do
      @controller.assigns.should be_an_instance_of(Hash)
    end
    
    it "should only contain the @stanza if the action hasn't been called yet" do
      @controller.assigns.should_not be_empty
      @controller.assigns["stanza"].should == @stanza
    end
    
    it "should return an hash containing all instance variables defined in the action" do
      vars = {"a" => 1, "b" => "b", "c" => { "d" => 4}}
      class MyController < Babylon::Base::Controller
        def do_something
          @a = 1
          @b = "b"
          @c = { "d" => 4 }
        end
      end
      @controller = MyController.new(@stanza)
      @controller.do_something
      @controller.assigns.should == vars.merge("stanza" => @stanza)
    end
  end

  describe ".view_path" do
    it "should return complete file path to the file given in param" do
      @controller = Babylon::Base::Controller.new()
      file_name = "myfile"
      @controller.__send__(:view_path, file_name).should == File.join("app/views", "#{"Babylon::Base::Controller".gsub("Controller","").downcase}", file_name)
    end
  end
  
  describe ".default_template_name" do
    before(:each) do
      @controller = Babylon::Base::Controller.new()
    end
    
    it "should return the view file name if a file is given in param" do
      @controller.__send__(:default_template_name, "myaction").should == "myaction.xml.builder"
    end
    
    it "should return the view file name based on the action_name if no file has been given" do
      @controller.action_name = "a_great_action"
      @controller.__send__(:default_template_name).should == "a_great_action.xml.builder"
    end
  end
  
  describe ".render_for_file" do
    
    before(:each) do
      @controller = Babylon::Base::Controller.new()
      @block = Proc.new {
        # Do something
      }
      @controller.class.send(:define_method, "action") do # Defining the action method
        # Do something
      end
      @controller.perform(:action, &@block) 
      @view = Babylon::Base::View.new("path_to_a_file", {})
    end
    
    it "should instantiate a new view, with the file provided and the hashed_variables" do
      Babylon::Base::View.should_receive(:new).with("path_to_a_file",an_instance_of(Hash)).and_return(@view)
      @controller.__send__(:render_for_file, "path_to_a_file")
    end
    
  end

end