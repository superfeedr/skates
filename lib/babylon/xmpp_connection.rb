module Babylon

  ## 
  # Connection Exception
  class NotConnected < Exception; end

  ## 
  # xml-not-well-formed Exception
  class XmlNotWellFormed < Exception; end

  ##
  # Error when there is no connection to the host and port.
  class NoConnection < Exception; end

  ##
  # Authentication Error (wrong password/jid combination). Used for Clients and Components
  class AuthenticationError < Exception; end

  ##
  # This class is in charge of handling the network connection to the XMPP server.
  class XmppConnection < EventMachine::Connection

    attr_accessor :jid, :host, :port

    ##
    # Connects the XmppConnection to the right host with the right port.
    # It passes itself (as handler) and the configuration
    # This can very well be overwritten by subclasses.
    def self.connect(params, handler)
      Babylon.logger.debug("CONNECTING TO #{params["host"]}:#{params["port"]} with #{handler.inspect} as connection handler") # Very low level Logging
      begin
        EventMachine.connect(params["host"], params["port"], self, params.merge({"handler" => handler}))
      rescue
        Babylon.logger.error("CONNECTION ERROR : #{$!.class} => #{$!}") # Very low level Logging
      end
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
    # Instantiate the Handler (called internally by EventMachine)
    def initialize(params)
      super()
      @connected = false
      @jid = params["jid"]
      @password = params["password"]
      @host = params["host"]
      @port = params["port"]
      @handler = params["handler"]
      @buffer = "" 
    end
    
    ##
    # Attaches a new parser since the network connection has been established.
    def post_init
      @parser = XmppParser.new(method(:receive_stanza))
    end   

    ##
    # Called when a full stanza has been received and returns it to the central router to be sent to the corresponding controller.
    def receive_stanza(stanza)
      Babylon.logger.debug("PARSED : #{stanza.to_xml}")
      # If not handled by subclass (for authentication)
      case stanza.name
      when "stream:error"
        if !stanza.children.empty? and stanza.children.first.name == "xml-not-well-formed"
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
    # Sends the Nokogiri::XML data (after converting to string) on the stream. Eventually it displays this data for debugging purposes.
    def send_xml(xml)
      raise NotConnected unless @connected
      return if xml.blank?
      begin
        Babylon.logger.debug("SENDING : #{xml}")
        xml.each do |element|
          send_data element.to_s
        end
      rescue
        Babylon.logger.error("#{$!}\n#{$!.backtrace.join("\n")}")
      end
    end

    private

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
