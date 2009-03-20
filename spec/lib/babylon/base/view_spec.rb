require File.dirname(__FILE__) + '/../../../spec_helper'

describe Babylon::Base::View do
  describe ".initialize" do
    
    before(:each) do
      @view = Babylon::Base::View.new("/a/path/to/a/view/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
    end
    
    it "should assign @output" do
      @view.output.should == ""
    end
    
    it "should assign @view_template to path" do
      @view.view_template == "/a/path/to/a/view/file"
    end
    
    it "should assign any variable passed in hash and create an setter for it" do
      {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}}.each do |key, value|
        @view.send(key).should == value
      end
    end
  end

  describe ".evaluate" do
    before(:each) do
      @view = Babylon::Base::View.new("/a/path/to/a/view/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @xml_string = <<-eoxml
       xml.message(:to => "you", :from => "me", :type => :chat) do |message|
         message.body("salut") 
       end
      eoxml
      File.stub!(:read).and_return(@xml_string)
    end
    
    it "should create a new Nokogiri Builder" do
      xml = Nokogiri::XML::Builder.new
      Nokogiri::XML::Builder.should_receive(:new).and_return(xml)
      @view.evaluate
    end
    
    it "should read the template file" do
      File.stub!(:read).and_return(@xml_string)
      @view.evaluate
    end
    
    it "should return a Nokogiri Nodeset corresponding to the childrend of the doc's root" do
      xml = Nokogiri::XML::Builder.new
      instance_eval(@xml_string)
      @view.evaluate.should.to_s == xml.doc.children.to_s
    end
    
  end
  
end