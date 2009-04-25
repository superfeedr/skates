require File.dirname(__FILE__) + '/../../../spec_helper'

describe Babylon::Base::View do
  describe ".initialize" do
    
    before(:each) do
      @view = Babylon::Base::View.new("/a/path/to/a/view/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
    end
    
    it "should assign @view_template to path" do
      @view.view_template == "/a/path/to/a/view/file"
    end
    
    it "should assign any variable passed in hash" do
      {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}}.each do |key, value|
        @view.instance_variable_get("@#{key}").should == value
      end
    end
  end

  describe ".evaluate" do
    before(:each) do
      @view_template = "/a/path/to/a/view/file"
      @view = Babylon::Base::View.new(@view_template, {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @xml_string = <<-eoxml
        xml.message(:to => "you", :from => "me", :type => :chat) do
          xml.body("salut") 
       end
      eoxml
    end
        
    it "should read the template file" do
      Babylon.views.should_receive(:[]).twice.with(@view_template).and_return(@xml_string)
      @view.evaluate
    end
    
    it "should raise an error if the view file couldn't be found" do
      Babylon.views.stub!(:[]).with(@view_template).and_raise(nil)
      lambda {
        @view.evaluate
      }.should raise_error(Babylon::Base::ViewFileNotFound)
    end
    
    it "should return a Nokogiri NodeSet" do
      Babylon.views.stub!(:[]).with(@view_template).and_return(@xml_string)
      @view.evaluate.should be_an_instance_of(Nokogiri::XML::NodeSet)
    end
    
    it "should call eval on the view file" do
      Babylon.views.stub!(:[]).with(@view_template).and_return(@xml_string)
      @view.should_receive(:eval).with(@xml_string)
      @view.evaluate
    end
    
    it "should be able to access context's variables" do
      Babylon.views.stub!(:[]).with(@view_template).and_return(@xml_string)
      @view = Babylon::Base::View.new("/a/path/to/a/view/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @xml_string = <<-eoxml
       message(:to => a, :from => b, :type => :chat) do
         body(c[:d]) 
       end
      eoxml
      @view.evaluate.to_s.should == "<message type=\"chat\" to=\"you\" from=\"me\">\n  <body>salut</body>\n</message>"
    end
  end
  
end