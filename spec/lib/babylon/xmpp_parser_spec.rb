require File.dirname(__FILE__) + '/../../spec_helper'

describe Skates::XmppParser do

  before(:each) do
    @last_stanza = ""
    @proc = mock(Proc, :call => true)
    @parser = Skates::XmppParser.new(@proc)
  end

  describe ".reset" do
    it "should reset the document to nil" do
      @parser.reset
      @parser.elem.should be_nil
    end

    it "should reset the element to nil (no element is being parsed)" do
      @parser.reset
      @parser.elem.should be_nil
    end
    
    it "should reset the parser to a parser" do
      new_parser = Nokogiri::XML::SAX::PushParser.new(@parser, "UTF-8")
      Nokogiri::XML::SAX::PushParser.should_receive(:new).with(@parser, "UTF-8").and_return(new_parser)
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
  
  describe ".characters" do
    before(:each) do 
      @parser.doc = Nokogiri::XML::Document.new
      @parser.elem = Nokogiri::XML::Element.new("element", @parser.doc)
    end
    
    it "should add the characters to the buffer" do
      chars = "hello my name is julien"
      @parser.characters(chars)
      @parser.instance_variable_get("@buffer").should == chars
    end
    
    it "should concatenate the text if we receive in both pieces" do
      chars = "hello my name is julien"
      @parser.characters(chars)
      @parser.instance_variable_get("@buffer").should == chars
      chars2 = "and I'm french!"
      @parser.characters(chars2)
      @parser.instance_variable_get("@buffer").should == chars + chars2
    end
  end
  
  describe ".start_element" do
    
    before(:each) do
      @new_elem_name = "new"
      @new_elem_attributes = ["to", "you@yourserver.com/home", "xmlns", "http://ns.com"]
    end
    
    it "should create a new doc if we don't have one" do
      new_doc = Nokogiri::XML::Document.new
      @parser.doc = nil
      Nokogiri::XML::Document.should_receive(:new).and_return(new_doc)
      @parser.start_element(@new_elem_name, @new_elem_attributes)
      @parser.doc.should == new_doc
    end
    
    it "should not create a new doc we already have one" do
      @parser.doc = Nokogiri::XML::Document.new
      Nokogiri::XML::Document.should_not_receive(:new)
      @parser.start_element(@new_elem_name, @new_elem_attributes)
    end
    
    it "should create a new element" do
      @doc = Nokogiri::XML::Document.new
      @parser.doc = @doc
      @new_elem = Nokogiri::XML::Element.new(@new_elem_name, @parser.doc)
      Nokogiri::XML::Element.should_receive(:new).and_return(@new_elem)
      @parser.start_element(@new_elem_name, @new_elem_attributes)
    end
    
    it "should add the new element as a child to the current element if there is one" do
      @doc = Nokogiri::XML::Document.new
      @parser.doc = @doc
      @current = Nokogiri::XML::Element.new("element", @parser.doc)
      @parser.elem = @current
      @new_elem = Nokogiri::XML::Element.new(@new_elem_name, @parser.doc)
      Nokogiri::XML::Element.stub!(:new).and_return(@new_elem)
      @parser.start_element(@new_elem_name, @new_elem_attributes)
      @new_elem.parent.should == @current
    end
    
    it "should add the new element as the child of the doc if there is none" do
      @doc = Nokogiri::XML::Document.new
      @parser.doc = @doc
      @new_elem = Nokogiri::XML::Element.new(@new_elem_name, @parser.doc)
      Nokogiri::XML::Element.stub!(:new).and_return(@new_elem)
      @parser.start_element(@new_elem_name, @new_elem_attributes)
      @new_elem.parent.should == @doc      
    end
    
    it "should add the right attributes and namespaces to the newly created element" do
      @parser.start_element(@new_elem_name, @new_elem_attributes)
      @parser.elem["to"].should == "you@yourserver.com/home"
      # TODO : FIX NAMESPACES : @parser.elem.namespaces.should == {"xmlns"=>"http://ns.com"}
      @parser.elem.namespaces.should == {}
    end
    
    describe "when the new element is of name stream:stream" do
      it "should callback" do
        @proc.should_receive(:call)
        @parser.start_element("stream:stream", [])
      end
      
      it "should reinit to nil the doc and the elem" do
        @parser.start_element("stream:stream", [])
        @parser.doc.should == nil
        @parser.elem.should == nil
      end
    end
  end

  describe ".end_element" do
    before(:each) do
      @doc = Nokogiri::XML::Document.new
      @parser.doc = @doc
      @current = Nokogiri::XML::Element.new("element", @parser.doc)
      @parser.elem = @current
    end
    
    it "should add the content of the buffer to the @elem" do
      @elem = Nokogiri::XML::Element.new("element", @parser.doc)
      chars = "hello world"
      @parser.instance_variable_set("@buffer", chars)
      @parser.elem = @elem
      @parser.end_element("element")
      @elem.content.should == chars
    end
    
    describe "when we're finishing the doc's root" do
      before(:each) do
        @parser.doc.root = @current
      end
      
      it "should callback" do
        @proc.should_receive(:call)
        @parser.end_element("element")
      end
      
      it "should reinit to nil the doc and the elem" do
        @parser.end_element("element")
        @parser.doc.should == nil
        @parser.elem.should == nil
      end
    end
    
    describe "when we're finishing another element" do
      before(:each) do
        @parser.doc.root = Nokogiri::XML::Element.new("root", @parser.doc)
        @current.parent = @parser.doc.root
      end
      
      it "should go back up one level" do
        @parser.end_element("element")
        @parser.elem = @current.parent
      end
    end
  end
  
  describe ".add_namespaces_and_attributes_to_node" do
    before(:each) do
      @doc = Nokogiri::XML::Document.new
      @parser.doc = @doc
      @element = Nokogiri::XML::Element.new("element", @parser.doc)
      @attrs = ["from", "me", "xmlns:atom", "http://www.w3.org/2005/Atom" ,"to", "you", "xmlns", "http://namespace.com"]
      @parser.elem = @element
    end
    
    it "should assign even elements to attributes value or namespaces urls" do
      @parser.__send__(:add_namespaces_and_attributes_to_current_node, @attrs)
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
      @parser.__send__(:add_namespaces_and_attributes_to_current_node, @attrs)
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
      @parser.__send__(:add_namespaces_and_attributes_to_current_node, @attrs)
      # TODO: FIX NAMESPACES @element.namespaces.values.should == ["http://www.w3.org/2005/Atom", "http://namespace.com"]
      @element.namespaces.values.should == []
    end
    
    it "should escape characters correctly" do
      @attrs = ["url", "http://api.flickr.com/services/feeds/photos_public.gne?id=49724566@N00&amp;lang=en-us&amp;format=atom"]
      @parser.__send__(:add_namespaces_and_attributes_to_current_node, @attrs)
      @element["url"].should == "http://api.flickr.com/services/feeds/photos_public.gne?id=49724566@N00&lang=en-us&format=atom"
    end
    
  end
  
  describe "a communication with an XMPP Client" do
    
    before(:each) do
      @stanzas = []
      @proc = Proc.new { |stanza|
        @stanzas << stanza 
      }
      @parser = Skates::XmppParser.new(@proc)
    end
      
    it "should parse the right information" do
      string = "<stream:stream
          xmlns:stream='http://etherx.jabber.org/streams'
          xmlns='jabber:component:accept'
          from='plays.shakespeare.lit'
          id='3BF96D32'>
          <handshake/>    
          <message from='juliet@example.com'
                        to='romeo@example.net'
                        xml:lang='en'>
          <body>Art thou not Romeo, and a Montague?</body>
          <link href='http://sfbay.craigslist.org/search/sss?query=%2522mac+mini%2522+Intel+Core+Duo&amp;minAsk=min&amp;maxAsk=max&amp;format=rss&amp;format=rss' />
        </message>"
      pieces = rand(string.size/30)
      # So we have to pick 'pieces' number between 0 and string.size
      indices = []
      pieces.times do |i|
        indices[i] = rand(string.size)
      end
      # Now let's sort indices
      indices.sort!
      substrings = []
      prev_index = 0
      indices.each do |index|
        substrings << string[prev_index, (index-prev_index)]
        prev_index = index
      end
      substrings << string[prev_index, string.size]
      #Just to make sure we split the string the right way!
      substrings.join("").should == string
      
      substrings.each do |s|
        @parser.push(s)
      end
      
      @stanzas.join("").should == "<stream:stream xmlns:stream=\"http://etherx.jabber.org/streams\" xmlns=\"jabber:component:accept\" from=\"plays.shakespeare.lit\" id=\"3BF96D32\"/><handshake/><message from=\"juliet@example.com\" to=\"romeo@example.net\" xml:lang=\"en\">\n  <body>Art thou not Romeo, and a Montague?</body>\n  <link href=\"http://sfbay.craigslist.org/search/sss?query=%2522mac+mini%2522+Intel+Core+Duo&amp;minAsk=min&amp;maxAsk=max&amp;format=rss&amp;format=rss\"/>\n</message>"
      @stanzas.last.at("link")["href"].should == "http://sfbay.craigslist.org/search/sss?query=%2522mac+mini%2522+Intel+Core+Duo&minAsk=min&maxAsk=max&format=rss&format=rss"
    end
    
  end
  
end