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
        message(:to => "you", :from => "me", :type => :chat) do
          body("salut") 
       end
      eoxml
      File.stub!(:read).and_return(@xml_string)
    end
        
    it "should read the template file" do
      File.stub!(:read).and_return(@xml_string)
      @view.evaluate
    end
    
    it "should return a Nokogiri Nodeset corresponding to the children of the doc's root" do
      @view.evaluate.should.to_s == "<message type='chat' to='you' from='me'><body>salut</body></message>"
    end
    
    it "should be able to access context's variables" do
      @view = Babylon::Base::View.new("/a/path/to/a/view/file", {:a => "a", :b => 123, :c => {:d => "d", :e => "123"}})
      @xml_string = <<-eoxml
       message(:to => a, :from => b, :type => :chat) do
         body(@context.c[:d]) 
       end
      eoxml
      File.stub!(:read).and_return(@xml_string)
      @view.evaluate.to_s.should == '<message type="chat" to="a" from="123"><body>d</body></message>'
    end
  end
  
end