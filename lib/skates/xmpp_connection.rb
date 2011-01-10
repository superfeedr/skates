module Skates
  
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
    # This will the host asynscrhonously and calls the block for each IP:Port pair.
    # if the block returns true, no other record will be tried. If it returns false, the block will be called with the next pair.
    def self.resolve(host, &block)
      block.call(false)
    end
    
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
      if params["host"] =~ /\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/ 
        params["port"] = params["port"] ? params["port"].to_i : 5222 
        _connect(params, handler)
      else
        resolve(params["host"]) do |host_info|
          if host_info
            begin
              _connect(params.merge(host_info), handler)
              true # connected! Yay!
            rescue NotConnected
              # It will try the next pair of ip/port
              false
            end
          else
            Skates.logger.error {
              "Sorry, we couldn't resolve #{srv_for_host(params["host"])} to any host that accept XMPP connections. Please provide a params[\"host\"]."
            }
            EM.stop_event_loop
          end
        end
      end
    end

    ##
    # Called when the connection is completed.
    def connection_completed
      @connected = true
      Skates.logger.debug {
        "CONNECTED"
      } # Very low level Logging
    end

    ##
    # Called when the connection is terminated and stops the event loop
    def unbind()
      @connected = false
      Skates.logger.debug {
        "DISCONNECTED"
      } # Very low level Logging
      begin
        @handler.on_disconnected() if @handler and @handler.respond_to?("on_disconnected")
      rescue
        Skates.logger.error {
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
      Skates.logger.debug {
        "PARSED : #{stanza.to_xml}"
      }
      # If not handled by subclass (for authentication)
      case stanza.name
      when "stream:error"
        if !stanza.children.empty? and stanza.children.first.name == "xml-not-well-formed"
          Skates.logger.error {
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
          Skates.logger.error {
            "on_stanza failed : #{$!}\n#{$!.backtrace.join("\n")}"
          }
        end
      end 
    end 

    ## 
    # Sends the Nokogiri::XML data (after converting to string) on the stream. Eventually it displays this data for debugging purposes.
    def send_xml(xml)
      begin
        if xml.is_a? Nokogiri::XML::NodeSet
          xml.each do |element|
            send_chunk(element.to_s)
          end
        else
          send_chunk(xml.to_s)
        end
      rescue
        Skates.logger.error {
          "SENDING FAILED: #{$!}"
        }
      end
    end
    
    private
    
    def send_chunk(string = "")
      raise NotConnected unless @connected
      return if string == ""
      raise StanzaTooBig, "Stanza Too Big (#{string.length} vs. #{XmppConnection.max_stanza_size})\n #{string}" if string.length > XmppConnection.max_stanza_size
      Skates.logger.debug {
        "SENDING : " + string
      }
      send_data UTF8Cleaner.clean(string)
    end

    ## 
    # receive_data is called when data is received. It is then passed to the parser. 
    def receive_data(data)
      data = UTF8Cleaner.clean(data)
      begin
        # Skates.logger.debug {
        #   "RECEIVED : #{data}"
        # }
        @parser.push(data) 
      rescue
        Skates.logger.error {
          "#{$!}\n#{$!.backtrace.join("\n")}"
        }
      end
    end
  
    def self.srv_for_host(host)
      "#{host}"
    end
  
    def self._connect(params, handler)
      Skates.logger.debug {
        "CONNECTING TO #{params["host"]}:#{params["port"]} with #{handler.inspect} as connection handler" # Very low level Logging
      }
      begin
        EventMachine.connect(params["host"], params["port"], self, params.merge({"handler" => handler}))
      rescue RuntimeError
        Skates.logger.error {
          "CONNECTION ERROR : #{$!.class} => #{$!}" # Very low level Logging
        }
        raise NotConnected
      end
      
    end
    
  end

end
