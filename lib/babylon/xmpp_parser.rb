module Babylon

  ##
  # This is the XML SAX Parser that accepts "pushed" content
  class XmppParser < Nokogiri::XML::SAX::Document
    
    attr_accessor :elem, :doc, :parser, :top
    
    ##
    # Initialize the parser and adds the callback that will be called upon stanza completion
    def initialize(callback)
      @callback = callback
      @buffer = ""
      super()
      reset
    end
    
    ## 
    # Resets the Pushed SAX Parser.
    def reset
      @parser   = Nokogiri::XML::SAX::PushParser.new(self, "UTF-8")
      start_document
      @elem     = nil
    end
    
    ##
    # Pushes the received data to the parser. The parser will then callback the document's methods (start_tag, end_tag... etc)
    def push(data)
      @parser << data
    end
    
    ## 
    # Called when the document received in the stream is started
    def start_document
      @doc = Nokogiri::XML::Document.new
    end
    
    ##
    # Adds characters to the current element (being parsed)
    def characters(string)
      @buffer += string 
    end

    ##
    # Instantiate a new current Element, adds the corresponding attributes and namespaces
    # The new element is eventually added to a parent element (if present).
    # If this element is the first element (the root of the document), then instead of adding it to a parent, we add it to the document itself. In this case, the current element will not be terminated, so we activate the callback immediately.
    def start_element(qname, attributes = [])
      e = Nokogiri::XML::Element.new(qname, @doc)
      add_namespaces_and_attributes_to_node(attributes, e)
      
      if e.name == "stream:stream"
        # Should be called only for stream:stream.
        # We re-initialize the document and set its root to be the newly created element.
        start_document
        @doc.root = e
        # Also, we activate the callback since this element  will never end.
        @callback.call(e)
      else
        # Adding the newly created element to the @elem that is being parsed, or, if no element is being parsed, then we set the @top and the @elem to be this newly created element.
        # @top is the "highest" element to (it's parent is the <stream> element)
        if @elem
          @elem = @elem.add_child(e)
        else
          if @doc.root.children.empty?
            @doc.root.add_child(e)
          else
            @doc.root.children.first.replace(e)
          end
          @elem = @top = e
        end
      end
    end

    ##
    # Terminates the current element and calls the callback
    def end_element(name)
      if @elem
        @elem.add_child(Nokogiri::XML::Text.new(decode(@buffer.strip), @doc)) unless @buffer.strip.empty?
        @buffer = "" # empty the buffer
        if @elem == @top 
          @callback.call(@elem) 
          # Remove the element from its content, since we're done with it!
          @elem.unlink
          # And the current elem is the next sibling or the root
          @elem = @top = nil
        else
          @elem = @elem.parent 
        end
      else
        # Not sure what to do since it seems we're not processing any element at this time, so how can one end?
      end
    end
    
    private
    
    ##
    # Adds namespaces and attributes. Nokogiri passes them as a array of [name, value, name, value]...
    def add_namespaces_and_attributes_to_node(attrs, node) 
      
      (attrs.size / 2).times do |i|
        name, value = attrs[2 * i], attrs[2 * i + 1]
        # We're intentionnaly not adding namespaces to stream:stream since it generates a lot of trouvble for xpath routing.
        if node.name == "stream:stream"
          node.set_attribute name, decode(value)
        elsif name == "xmlns"
          node.add_namespace(nil, value)
        elsif name =~ /\Axmlns:/
          node.add_namespace(name.gsub("xmlns:", ""), value)
        else
          node.set_attribute name, decode(value)
        end
      end
    end
    
    def decode(str)
      @entities ||= {
        'lt'    => '<',
        'gt'    => '>',
        'amp'   => '&',
        'quot'  => '"',
        '#13'   => "\r",
      }

      @entities.keys.inject(str) { |string,key|
        string.gsub(/&#{key};/, @entities[key])
      }
    end
    
  end

end
