module Babylon

  ##
  # This is the XML SAX Parser that accepts "pushed" content
  class XmppParser < Nokogiri::XML::SAX::Document
    
    attr_accessor :elem, :doc, :parser
    
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
      @parser = Nokogiri::XML::SAX::PushParser.new(self, "UTF-8")
      @elem = @doc = nil
    end
    
    ##
    # Pushes the received data to the parser. The parser will then callback the document's methods (start_tag, end_tag... etc)
    def push(data)
      @parser << data
    end
    
    ##
    # Adds characters to the current element (being parsed)
    def characters(string)
      @buffer += string 
    end

    ##
    # Instantiate a new current Element, adds the corresponding attributes and namespaces.
    # The new element is eventually added to a parent element (if present).
    # If no element is being parsed, then, we create a new document, to which we add this new element as root. (we create one document per stanza to avoid memory problems)
    def start_element(qname, attributes = [])
      @doc ||= Nokogiri::XML::Document.new
      @elem ||= @doc # If we have no current element, then, we take the doc
      @elem = @elem.add_child(Nokogiri::XML::Element.new(qname, @doc))
      add_namespaces_and_attributes_to_current_node(attributes)
      
      if @elem.name == "stream:stream"
        # We activate the callback since this element  will never end.
        @callback.call(@elem)
        @doc = @elem = nil # Let's prepare for the next stanza
      end
    end

    ##
    # Terminates the current element and calls the callback
    def end_element(name)
      if @elem
        @elem.add_child(Nokogiri::XML::Text.new(decode(@buffer.strip), @doc)) unless @buffer.strip.empty?
        @buffer = "" # empty the buffer
        if @elem == @doc.root 
          # If we're actually finishing the stanza (a stanza is always a document's root)
          @callback.call(@elem) 
          # We delete the current element and the doc (1 doc per stanza policy)
          @elem = @doc = nil
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
    def add_namespaces_and_attributes_to_current_node(attrs) 
      (attrs.size / 2).times do |i|
        name, value = attrs[2 * i], attrs[2 * i + 1]
        # TODO : FIX namespaces :they give a lot of problems with XPath
        # if name == "xmlns"
        #   @elem.add_namespace(nil, value)
        # elsif name =~ /\Axmlns:/
        #   @elem.add_namespace(name.gsub("xmlns:", ""), value)
        # else
          @elem.set_attribute name, decode(value)
        # end
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
