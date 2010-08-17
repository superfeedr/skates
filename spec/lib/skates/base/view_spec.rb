require File.dirname(__FILE__) + '/../../../spec_helper'

describe Skates::Base::View do
  describe :initialize do
    
    before(:each) do
      @view = Skates::Base::View.new("/a/path/to/views/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
    end
    
    it "should assign @view_template to path" do
      @view.view_template == "/a/path/to/views/file"
    end
    
    it "should assign any variable passed in hash" do
      {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}}.each do |key, value|
        @view.instance_variable_get("@#{key}").should == value
      end
    end
  end

  describe :evaluate do
    before(:each) do
      @view_template = "/a/path/to/views/file"
      @view = Skates::Base::View.new(@view_template, {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @xml_string = <<-eoxml
        xml.message(:to => "you", :from => "me", :type => :chat) do
          xml.body("salut") 
       end
      eoxml
      Skates.views.stub!(:[]).with(@view_template).and_return(@xml_string)
    end
        
    it "should read the template file" do
      Skates.views.should_receive(:[]).twice.with(@view_template).and_return(@xml_string)
      @view.evaluate
    end
    
    it "should raise an error if the view file couldn't be found" do
      Skates.views.stub!(:[]).with(@view_template).and_raise(nil)
      lambda {
        @view.evaluate
      }.should raise_error(Skates::Base::ViewFileNotFound)
    end
    
    it "should return a Nokogiri NodeSet" do
      Skates.views.stub!(:[]).with(@view_template).and_return(@xml_string)
      @view.evaluate.should be_an_instance_of(Nokogiri::XML::NodeSet)
    end
    
    it "should call eval on the view file" do
      Skates.views.stub!(:[]).with(@view_template).and_return(@xml_string)
      @view.should_receive(:eval).with(@xml_string, an_instance_of(Binding), @view_template, 1)
      @view.evaluate
    end
    
    it "should be able to access context's variables" do
      @view = Skates::Base::View.new("/a/path/to/views/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @view.instance_variable_get("@a").should == "a"
      @view.instance_variable_get("@b").should == 123
      @view.instance_variable_get("@c").should == {:e=>"123", :d=>"d"}
    end
  end
  
  describe :render do
    before(:each) do
      @view_template = "/a/path/to/views/file"
      @view = Skates::Base::View.new(@view_template, {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      
      @xml_string = <<-eoxml
        xml.message(:to => "you", :from => "me", :type => :chat) do |message|
          message.body("salut") 
          render(message, {:partial => "partial", :locals => {:subtitle => "bonjour monde"}})
          render(message, {:partial => "../other_views/partial", :locals => {:subtitle => "bonjour monde", :name => "Joe"}})
       end
      eoxml
      
      @partial_string = <<-eoxml
        xml.title("hello word")
        xml.subtitle(subtitle)
      eoxml

      @partial_in_annother_controller_string = <<-eoxml
        xml.name(name)
      eoxml
      
      Skates.views.stub!(:[]).with(@view_template).and_return(@xml_string)      
      Skates.views.stub!(:[]).with("/a/path/to/views/partial.xml.builder").and_return(@partial_string)      
      Skates.views.stub!(:[]).with("/a/path/to/other_views/partial.xml.builder").and_return(@partial_in_annother_controller_string) 
    end
    
    it "should render the partial in the right context" do
      @view.evaluate.xpath("//message/title").text.should == "hello word"
    end
    
    it "should allocate the locals variables" do
      @view.evaluate.xpath("//message/subtitle").text.should == "bonjour monde"
    end
    
    it "should cleanup the path so only canonical paths are used" do
      @view.evaluate.xpath("//message/name").text.should == "Joe"
    end
    
  end
  
end