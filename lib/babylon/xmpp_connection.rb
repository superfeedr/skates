module Babylon

  ## 
  # Connection Exception
  class NotConnected < Exception; end

  ## 
  # xml-not-well-formed Exception
  class XmlNotWellFormed < Exception; end

  ##
  # Authentication Error (wrong password/jid combination). Used for Clients and Components
  class AuthenticationError < Exception; end

  ##
  # This class is in charge of handling the network connection to the XMPP server.
  class XmppConnection < EventMachine::Connection

    attr_accessor :jid, :host, :port

    ##
    # Connects the XmppConnection to the right host with the right port. I
    # It passes itself (as handler) and the configuration
    # This can very well be overwritten by subclasses.
    def self.connect(params, handler)
      Babylon.logger.debug("CONNECTING TO #{params["host"]}:#{params["port"]}") # Very low level Logging
      EventMachine.connect(params["host"], params["port"], self, params.merge({"handler" => handler}))
    end

    def connection_completed
      @connected = true
      Babylon.logger.debug("CONNECTED") # Very low level Logging
    end

    ##
    # Called when the connection is terminated and stops the event loop
    def unbind()
      @connected = false
      Babylon.logger.debug("DISCONNECTED") # Very low level Logging
      begin
        @handler.on_disconnected() if @handler and @handler.respond_to?("on_disconnected")
      rescue
        Babylon.logger.error("on_disconnected failed : #{$!}\n#{$!.backtrace.join("\n")}")
      end
    end

    ## 
    # Instantiate the Handler (called internally by EventMachine) and attaches a new XmppParser
    def initialize(params)
      super()
      @connected = false
      @jid = params["jid"]
      @password = params["password"]
      @host = params["host"]
      @port = params["port"]
      @handler = params["handler"]
      @parser = XmppParser.new(&method(:receive_stanza))
    end

    ##
    # Called when a full stanza has been received and returns it to the central router to be sent to the corresponding controller.
    def receive_stanza(stanza)
      Babylon.logger.debug("PARSED : #{stanza.to_xml}")
      # If not handled by subclass (for authentication)
      case stanza.name
      when "stream:error"
        if !stanza.children.empty? and stanza.children.first.name == "xml-not-well-formed"
          # <stream:error><xml-not-well-formed xmlns:xmlns="urn:ietf:params:xml:ns:xmpp-streams"/></stream:error>
          Babylon.logger.error("DISCONNECTED DUE TO MALFORMED STANZA")
          raise XmlNotWellFormed
        end
        # In any case, we need to close the connection.
        close_connection
      else
        begin
          @handler.on_stanza(stanza) if @handler and @handler.respond_to?("on_stanza")
        rescue
          Babylon.logger.error("on_stanza failed : #{$!}\n#{$!.backtrace.join("\n")}")
        end
      end 
    end 

    ## 
    # Sends the Nokogiri::XML data (after converting to string) on the stream. It also appends the right "from" to be the component's JId if none has been mentionned. Eventually it displays this data for debugging purposes.
    # This method also adds a "from" attribute to all stanza if it was ommited (the full jid) only if a "to" attribute is present. if not, we assume that we're speaking to the server and the server doesn't need a "from" to identify where the message is coming from.
    def send_xml(xml)
      raise NotConnected unless @connected
      if xml.is_a? Nokogiri::XML::NodeSet
        xml.each do |node|
          send_node(node)
        end
      elsif xml.is_a? Nokogiri::XML::Node
        send_node(xml)
      else
        # We try a cast into a string.
        send_string("#{xml}")
      end
    end

    private

    ##
    # Sends a node on the "line".
    def send_node(node)
      node["from"] ||= jid if node["to"]
      send_string(node.to_xml)
    end

    ## 
    # Sends a string on the line
    def send_string(string)
      begin
        Babylon.logger.debug("SENDING : #{string}")
        send_data("#{string}") 
      rescue
        Babylon.logger.error("#{$!}\n#{$!.backtrace.join("\n")}")
      end
    end

    ## 
    # receive_data is called when data is received. It is then passed to the parser. 
    def receive_data(data)
      begin
        Babylon.logger.debug("RECEIVED : #{data}")
        @parser.push(data)
      rescue
        Babylon.logger.error("#{$!}\n#{$!.backtrace.join("\n")}")
      end
    end
  end

end
