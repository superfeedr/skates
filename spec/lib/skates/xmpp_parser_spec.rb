$: << "." # Adding the local directory to the path, so we can safely require models, controllers and views.
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

    it "should not parse text content as XML" do
      stanza = "<message><body>&amp;#187;</body></message>"
      @parser.push stanza
      # Not "\273":
      (@parser.elem / 'message/body')[0].content.should == '&#187;'
      (@parser.elem / 'message/body').to_xml.should == "<body>&amp;#187;</body>"
    end
  end
  
  describe ".start_element" do
    
    before(:each) do
      @new_elem_name = "new"
      @new_elem_attributes = [["to", "you@yourserver.com/home"], ["xmlns", "http://ns.com"]]
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
      @parser.elem.namespaces.should == {"xmlns"=>"http://ns.com"}
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
      
      @stanzas.map(&:to_xml).join("").should == "<stream xmlns:stream=\"http://etherx.jabber.org/streams\" xmlns=\"jabber:component:accept\" from=\"plays.shakespeare.lit\" id=\"3BF96D32\"/><handshake/><message from=\"juliet@example.com\" to=\"romeo@example.net\" xml:lang=\"en\">\n  <body>Art thou not Romeo, and a Montague?</body>\n  <link href=\"http://sfbay.craigslist.org/search/sss?query=%2522mac+mini%2522+Intel+Core+Duo&amp;minAsk=min&amp;maxAsk=max&amp;format=rss&amp;format=rss\"/>\n</message>"
      @stanzas.last.at("link")["href"].should == "http://sfbay.craigslist.org/search/sss?query=%2522mac+mini%2522+Intel+Core+Duo&minAsk=min&maxAsk=max&format=rss&format=rss"
    end
    
  end
  
  describe "when parsing a complex stanza" do
    before(:each) do
      @xml =<<-EOXML
<iq id="pub-296" to="test-track.superfeedr.com" type="set">
  <feed xmlns="http://superfeedr.com/xmpp-superfeedr-ext" id="368">
    <url>http://superfeedr.com/dummy.xml</url>
    <http_code>200</http_code>
    <etag>"eb8dfc6fa342dc8326851907efe35cda"</etag>
    <number_of_new_entries>10</number_of_new_entries>
    <last_error_message>7462B in 1.036602s, 10/10 new entries</last_error_message>
    <last_fetch>2011-02-21T14:34:52-05:00</last_fetch>
    <next_fetch>2011-02-21T14:38:37-05:00</next_fetch>
    <period>225</period>
    <last_maintenance_at>2011-02-21T14:34:52-05:00</last_maintenance_at>
    <entries_count>10</entries_count>
    <perform_maintenance>true</perform_maintenance>
    <title>The Dummy Time Feed</title>
    <format>feed</format>
    <link href="http://superfeedr.com" rel="alternate" type="text/html"/>
    <link href="http://superfeedr.com/dummy.xml" rel="self" type="application/atom+xml"/>
    <last_parse>2011-02-21T14:34:52-05:00</last_parse>
    <headers>
      <server>nginx/0.8.52</server>
      <date>Mon, 21 Feb 2011 19:35:41 GMT</date>
      <content_type>application/xml; charset=utf-8</content_type>
      <connection>close</connection>
      <status>200 OK</status>
      <etag>"eb8dfc6fa342dc8326851907efe35cda"</etag>
      <x_runtime>858</x_runtime>
      <content_length>7462</content_length>
      <set_cookie/>
      <cache_control>private, max-age=0, must-revalidate</cache_control>
    </headers>
    <id>tag:superfeedr.com,2005:/hubbub/dummy</id>
  </feed>
  <pubsub xmlns="http://jabber.org/protocol/pubsub">
    <publish node="368">
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298307758</id>
          <published>2011-02-21T12:02:38-05:00</published>
          <updated>2011-02-21T12:02:38-05:00</updated>
          <title>17:02:38</title>
          <summary type="text"/>
          <content type="text">Monday February 21 17:02:38 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298307758" title="17:02:38" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298307618</id>
          <published>2011-02-21T12:00:18-05:00</published>
          <updated>2011-02-21T12:00:18-05:00</updated>
          <title>17:00:18</title>
          <summary type="text"/>
          <content type="text">Monday February 21 17:00:18 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298307618" title="17:00:18" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298307454</id>
          <published>2011-02-21T11:57:34-05:00</published>
          <updated>2011-02-21T11:57:34-05:00</updated>
          <title>16:57:34</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:57:34 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298307454" title="16:57:34" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298307099</id>
          <published>2011-02-21T11:51:39-05:00</published>
          <updated>2011-02-21T11:51:39-05:00</updated>
          <title>16:51:39</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:51:39 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298307099" title="16:51:39" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298305317</id>
          <published>2011-02-21T11:21:57-05:00</published>
          <updated>2011-02-21T11:21:57-05:00</updated>
          <title>16:21:57</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:21:57 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298305317" title="16:21:57" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298305151</id>
          <published>2011-02-21T11:19:11-05:00</published>
          <updated>2011-02-21T11:19:11-05:00</updated>
          <title>16:19:11</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:19:11 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298305151" title="16:19:11" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298304372</id>
          <published>2011-02-21T11:06:12-05:00</published>
          <updated>2011-02-21T11:06:12-05:00</updated>
          <title>16:06:12</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:06:12 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298304372" title="16:06:12" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298304371</id>
          <published>2011-02-21T11:06:11-05:00</published>
          <updated>2011-02-21T11:06:11-05:00</updated>
          <title>16:06:11</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:06:11 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298304371" title="16:06:11" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298304085</id>
          <published>2011-02-21T11:01:25-05:00</published>
          <updated>2011-02-21T11:01:25-05:00</updated>
          <title>16:01:25</title>
          <summary type="text"/>
          <content type="text">Monday February 21 16:01:25 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298304085" title="16:01:25" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
      <item>
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:geo="http://www.georss.org/georss" xmlns:as="http://activitystrea.ms/spec/1.0/" xmlns:sf="http://superfeedr.com/xmpp-pubsub-ext" xml:lang="en-US">
          <id>tag:superfeedr.com,2005:String/1298303653</id>
          <published>2011-02-21T10:54:13-05:00</published>
          <updated>2011-02-21T10:54:13-05:00</updated>
          <title>15:54:13</title>
          <summary type="text"/>
          <content type="text">Monday February 21 15:54:13 UTC 2011 Somebody wanted to know what time it was.</content>
          <geo:point>37.773721,-122.414957</geo:point>
          <link href="http://superfeedr.com/?1298303653" title="15:54:13" rel="alternate" type="text/html"/>
          <category term="tests"/>
          <author>
            <name>Superfeedr</name>
            <uri>http://superfeedr.com/</uri>
            <email>julien@superfeedr.com</email>
          </author>
        </entry>
      </item>
    </publish>
  </pubsub>
</iq>
EOXML
      
      @proc = Proc.new { |stanza|  
        stanza.to_xml.should == @xml.strip
      }
      @parser = Skates::XmppParser.new(@proc) 
    end
    
    it "should parse correctly the namespaces and the attributes" do
      @parser.push(@xml)
    end
  end
  
end