module Babylon
  
  ## 
  # Connection Exception
  class NotConnected < StandardError; end

  ## 
  # xml-not-well-formed Exception
  class XmlNotWellFormed < StandardError; end

  ##
  # Error when there is no connection to the host and port.
  class NoConnection < StandardError; end

  ##
  # Authentication Error (wrong password/jid combination). Used for Clients and Components
  class AuthenticationError < StandardError; end

  ##
  # Raised when the application tries to send a stanza that might be rejected by the server because it's too long.
  class StanzaTooBig < StandardError; end

  ##
  # This class is in charge of handling the network connection to the XMPP server.
  class XmppConnection < EventMachine::Connection
    
    attr_accessor :jid, :host, :port
    
    @@max_stanza_size = 65535
    
    ##
    # Maximum Stanza size. Default is 65535
    def self.max_stanza_size
      @@max_stanza_size
    end
    
    ##
    # Setter for Maximum Stanza size.
    def self.max_stanza_size=(_size)
      @@max_stanza_size = _size
    end

    ##
    # Connects the XmppConnection to the right host with the right port.
    # It passes itself (as handler) and the configuration
    # This can very well be overwritten by subclasses.
    def self.connect(params, handler)
      Babylon.logger.debug {
        "CONNECTING TO #{params["host"]}:#{params["port"]} with #{handler.inspect} as connection handler" # Very low level Logging
      }
      begin
        EventMachine.connect(params["host"], params["port"], self, params.merge({"handler" => handler}))
      rescue RuntimeError
        Babylon.logger.error {
          "CONNECTION ERROR : #{$!.class} => #{$!}" # Very low level Logging
        }
        raise NotConnected
      end
    end

    ##
    # Called when the connection is completed.
    def connection_completed
      @connected = true
      Babylon.logger.debug {
        "CONNECTED"
      } # Very low level Logging
    end

    ##
    # Called when the connection is terminated and stops the event loop
    def unbind()
      @connected = false
      Babylon.logger.debug {
        "DISCONNECTED"
      } # Very low level Logging
      begin
        @handler.on_disconnected() if @handler and @handler.respond_to?("on_disconnected")
      rescue
        Babylon.logger.error {
          "on_disconnected failed : #{$!}\n#{$!.backtrace.join("\n")}"
        }
      end
    end

    ## 
    # Instantiate the Handler (called internally by EventMachine)
    def initialize(params = {})
      @connected = false
      @jid       = params["jid"]
      @password  = params["password"]
      @host      = params["host"]
      @port      = params["port"]
      @handler   = params["handler"]
      @buffer    = "" 
    end
    
    ##
    # Attaches a new parser since the network connection has been established.
    def post_init
      @parser = XmppParser.new(method(:receive_stanza))
    end   

    ##
    # Called when a full stanza has been received and returns it to the central router to be sent to the corresponding controller.
    def receive_stanza(stanza)
      Babylon.logger.debug {
        "PARSED : #{stanza.to_xml}"
      }
      # If not handled by subclass (for authentication)
      case stanza.name
      when "stream:error"
        if !stanza.children.empty? and stanza.children.first.name == "xml-not-well-formed"
          Babylon.logger.error {
            "DISCONNECTED DUE TO MALFORMED STANZA"
          }
          raise XmlNotWellFormed
        end
        # In any case, we need to close the connection.
        close_connection
      else
        begin
          @handler.on_stanza(stanza) if @handler and @handler.respond_to?("on_stanza")
        rescue
          Babylon.logger.error {
            "on_stanza failed : #{$!}\n#{$!.backtrace.join("\n")}"
          }
        end
      end 
    end 

    ## 
    # Sends the Nokogiri::XML data (after converting to string) on the stream. Eventually it displays this data for debugging purposes.
    def send_xml(xml)
      if xml.is_a? Nokogiri::XML::NodeSet
        xml.each do |element|
          send_chunk(element.to_s)
        end
      else
        send_chunk(xml.to_s)
      end
    end

    private

    def send_chunk(string)
      raise NotConnected unless @connected
      return if string.blank?
      raise StanzaTooBig, "Stanza Too Big (#{string.length} vs. #{XmppConnection.max_stanza_size})\n #{string}" if string.length > XmppConnection.max_stanza_size
      Babylon.logger.debug {
        "SENDING : " + string
      }
      send_data string
    end

    ## 
    # receive_data is called when data is received. It is then passed to the parser. 
    def receive_data(data)
      begin
        # Babylon.logger.debug {
        #   "RECEIVED : #{data}"
        # }
        @parser.push(data) 
      rescue
        Babylon.logger.error {
          "#{$!}\n#{$!.backtrace.join("\n")}"
        }
      end
    end
  end

end
