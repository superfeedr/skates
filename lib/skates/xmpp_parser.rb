module Skates

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
      @buffer ||= ""
      @buffer << string 
    end
    
    ##
    # Instantiate a new current Element, adds the corresponding attributes and namespaces.
    # The new element is eventually added to a parent element (if present).
    # If no element is being parsed, then, we create a new document, to which we add this new element as root. (we create one document per stanza to avoid memory problems)
    def start_element(qname, attributes = [])
      clear_characters_buffer
      @doc ||= Nokogiri::XML::Document.new
      @elem ||= @doc # If we have no current element, then, we take the doc
      @elem = @elem.add_child(Nokogiri::XML::Element.new(qname, @doc))
      
      add_namespaces_and_attributes_to_current_node(attributes)
      
      if @elem.name == "stream:stream"
        # We activate the callback since this element  will never end.
        @callback.call(@elem)
        @doc = @elem = nil # Let's prepare for the next stanza
        # And then, we start a new Sax Push Parser
      end
    end
    
    ##
    # Clears the characters buffer
    def clear_characters_buffer
      if @buffer && @elem
        @buffer.strip!
        @elem.add_child(Nokogiri::XML::Text.new(@buffer, @doc)) unless @buffer.empty?
        @buffer = nil # empty the buffer
      end
    end

    ##
    # Terminates the current element and calls the callback
    def end_element(name)
      clear_characters_buffer
      if @elem
        if @elem.parent == @doc
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
    
    ##
    # Adds namespaces and attributes. Nokogiri passes them as a array of [[ns_name, ns_url], [ns_name, ns_url]..., key, value, key, value]...
    def add_namespaces_and_attributes_to_current_node(attrs) 
      # Namespaces
      attrs.select {|k| k.is_a? Array}.each do |pair|
        set_namespace(pair[0], pair[1])
        # set_normal_attribute(pair[0], pair[1])
      end
      # Attributes
      attrs.select {|k| k.is_a? String}.in_groups_of(2) do |pair|
        set_normal_attribute(pair[0], pair[1])
      end
    end
        
    def set_normal_attribute(key, value)
      @elem.set_attribute key, Skates.decode_xml(value)
    end
    
    def set_namespace(key, value)
      if key.include? ':'
        @elem.add_namespace(key.split(':').last, value)
      else
        @elem.add_namespace(nil, value)
      end
    end
  end 
end 
