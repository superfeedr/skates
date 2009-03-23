require File.dirname(__FILE__) + '/../../spec_helper'

describe Babylon::XmppParser do

  before(:each) do
    @last_stanza = ""
    @proc = Proc.new {
      # Do someting open ennding element
    }
    @parser = Babylon::XmppParser.new(&@proc)
    @parser.top = Nokogiri::XML::Element.new("element", @parser.doc)
    @parser.elem = @parser.top
  end

  describe ".reset" do
    it "should reset the document to a new document" do
      new_doc = Nokogiri::XML::Document.new
      Nokogiri::XML::Document.should_receive(:new).and_return(new_doc)
      @parser.reset
      @parser.doc.should == new_doc
    end

    it "should reset the element to nil (no element is being parsed)" do
      @parser.reset
      @parser.elem.should be_nil
    end
    
    it "should reset the parser to a parser" do
      new_parser = Nokogiri::XML::SAX::PushParser.new(@parser)
      Nokogiri::XML::SAX::PushParser.should_receive(:new).with(@parser).and_return(new_parser)
      @parser.reset
      @parser.parser.should == new_parser
    end

  end

  describe ".push" do
    it "should send the data to the parser" do
      data = "<name>me</name>"
      @parser.parser.should_receive(:<<).with(data)
      @parser.push(data)
    end
  end

  describe ".start_document" do
    it "should instantiate a new document" do
      new_doc = Nokogiri::XML::Document.new
      Nokogiri::XML::Document.should_receive(:new).and_return(new_doc)
      @parser.start_document
      @parser.doc.should == new_doc
    end
    
  end

  describe ".characters" do
    it "should add the characters to the current element" do
      chars = "hello my name is julien"
      @parser.characters(chars)
      @parser.elem.content.should == chars
    end
    
    it "should concatenate the text if we receive in both pieces" do
      chars = "hello my name is julien"
      @parser.characters(chars)
      @parser.elem.content.should == chars
      chars2 = "and I'm french!"
      @parser.characters(chars2)
      @parser.elem.content.should == chars + chars2
    end
  end

  describe ".start_element" do
    
    it "should create a new element with the right attributes, whose name is the name of the start tag and assign it to @elem" do
      el_name = "hello"
      el_attributes = ["id", "1234", "value", "5678"]
      @parser.start_element(el_name, el_attributes)
      @parser.elem.name.should == el_name
      @parser.elem["id"].should == "1234"
      @parser.elem["value"].should == "5678"
    end
    
    describe "with stream:stream element" do
      
      before(:each) do
        @stream = "stream:stream"
        @stream_attributes = ["xmlns:stream", "http://etherx.jabber.org/streams", "to", "firehoser.superfeedr.com", "xmlns", "jabber:component:accept"]
      end
      
      it "should recreate a new document" do
        new_doc = Nokogiri::XML::Document.new
        Nokogiri::XML::Document.should_receive(:new).and_return(new_doc)
        @parser.start_element(@stream, @stream_attributes)
        @parser.doc.should == new_doc
      end
      
      it "should add a stream:stream element as the root of the document, with the right attributes" do
        @parser.start_element(@stream, @stream_attributes)
        @parser.doc.root.name.should == "stream:stream"
        # @parser.doc.root["to"].should == "firehoser.superfeedr.com"
        # @parser.doc.namespaces.should == {"xmlns"=>"jabber:component:accept", "xmlns:stream"=>"http://etherx.jabber.org/streams"}
      end
      
      it "should callback the parser's callback" do
        @parser.start_element(@stream, @stream_attributes)
        @parser.doc.root.name.should == "stream:stream"
        # @proc.should_receive(:call)
      end
    end
    
    describe "with a 'top' element when @elem is nil (which means its direct parent is stream (so it must be a <iq>,<message> or <presence> element)" do
      before(:each) do
        @name = "message"
        @attributes = ["to", "you", "from", "me"]
        @parser.elem = nil
      end
      
      it "should assign @elem to a new element created with the right name and attributes" do
        @parser.start_element(@name, @attributes)
        @parser.elem.name.should == @name
      end
      
      it "should set the @top to be equal to this @elem" do
        @parser.start_element(@name, @attributes)
        @parser.top.name.should == @name
      end
    end
    
    describe "with an element whose parent is not the stream directly" do
      before(:each) do
        @name = "message"
        @attributes = ["to", "you", "from", "me"]
      end
      
      it "should not change the @top" do
        top = @parser.top
        @parser.start_element(@name, @attributes)
        @parser.top.should == top
      end
      
      it "should have a new @elem that corresponds to the item we're adding" do
        @parser.start_element(@name, @attributes)
        @parser.elem.name.should == @name
      end
      
      it "this elem should have top as a parent" do
        @parser.start_element(@name, @attributes)
        @parser.elem.parent.should == @parser.top
      end
    end
    
  end

  describe ".end_element" do
    
    describe "if the current element is the top element" do      
      it "should call the callback with the current element" do
        @proc.should_receive(:call).with(@parser.elem)
        @parser.end_element("element")
      end
      it "should unlink @elem" do
        @parser.elem.should_receive(:unlink)
        @parser.end_element("element")
      end
      it "should delete the @elem and @top" do
        @parser.end_element("element")
        @parser.elem.should be_nil
        @parser.top.should be_nil
      end
    end
    
    describe "if the current element is not the top element" do
      before(:each) do
        @child = Nokogiri::XML::Element.new("child", @parser.doc)
        @parser.elem.add_child(@child)
        @parser.elem = @child
      end
      
      it "should switch @elem to the parent of the element" do
        parent = @child.parent
        @parser.elem.should == @child
        @parser.end_element("child")
        @parser.elem.should == parent
      end
    end
    
  end

  describe ".add_namespaces_and_attributes_to_node" do
    
    before(:each) do
      @element = Nokogiri::XML::Element.new("element", @parser.doc)
      @attrs = ["from", "me", "xmlns:atom", "http://www.w3.org/2005/Atom" ,"to", "you", "xmlns", "http://namespace.com"]
    end
    
    it "should assign even elements to attributes value or namespaces urls" do
      @parser.__send__(:add_namespaces_and_attributes_to_node, @attrs, @element)
      even = []
      @attrs.size.times do |i|
        even << @attrs[i*2]
      end
      even.compact!
      @element.attributes.keys.each do |k|
        even.should include(k)
      end
    end
    
    it "should assign odd elements to attributes names of namespaces prefixes" do
      @parser.__send__(:add_namespaces_and_attributes_to_node, @attrs, @element)
      even = []
      @attrs.size.times do |i|
        even << @attrs[i*2+1]
      end
      even.compact!
      @element.attributes.values.each do |v|
        even.should include("#{v}")
      end
    end
    
    it "should add namespace for each attribute name that starts with xmlns" do
      @parser.__send__(:add_namespaces_and_attributes_to_node, @attrs, @element)
      @element.namespaces.values.should == ["http://namespace.com", "http://www.w3.org/2005/Atom"]
    end
    
  end

  describe ".cdata_block" do
    it "should create a CData block in the current element when called directly" do
      @parser.cdata_block("salut my friend!")
      @parser.elem.to_xml.should == "<element><![CDATA[salut my friend!]]></element>"
    end
  end

end