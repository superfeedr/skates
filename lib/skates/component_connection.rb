module Skates
  ##
  # ComponentConnection is in charge of the XMPP connection itself.
  # Upon stanza reception, and depending on the status (connected... etc), this component will handle or forward the stanzas.
  class ComponentConnection < XmppConnection
    
    def self.connect(params, handler)
      params["host"] ||= params["jid"]
      super(params, handler)
    end
    
    ##
    # Creates a new ComponentConnection and waits for data in the stream
    def initialize(params)
      super(params)
      @state = :wait_for_stream
    end
    
    ##
    # Connection_completed is called when the connection (socket) has been established and is in charge of "building" the XML stream 
    # to establish the XMPP connection itself.
    # We use a "tweak" here to send only the starting tag of stream:stream
    def connection_completed
      super
      doc = Nokogiri::XML::Document.new 
      stream = Nokogiri::XML::Node.new("stream:stream", doc)
      stream["xmlns"] = stream_namespace
      stream["xmlns:stream"] = "http://etherx.jabber.org/streams"
      stream["to"] = jid
      doc.add_child(stream)
      paste_content_here= Nokogiri::XML::Node.new("paste_content_here", doc)
      stream.add_child(paste_content_here)
      start, stop = doc.to_xml.split('<paste_content_here/>')
      send_xml(start)
    end

    ##
    # XMPP Component handshake as defined in XEP-0114:
    # http://xmpp.org/extensions/xep-0114.html
    def receive_stanza(stanza)
      case @state
      when :connected # Most frequent case
          super(stanza) # Can be dispatched
          
      when :wait_for_stream
        if stanza.name == "stream" && stanza.attributes['id']
          # This means the XMPP session started!
          # We must send the handshake now.
          send_xml(handshake(stanza))
          @state = :wait_for_handshake
        else
          raise
        end

      when :wait_for_handshake
        if stanza.name == "handshake"
          begin
            @handler.on_connected(self) if @handler and @handler.respond_to?("on_connected")
          rescue
            Skates.logger.error {
              "on_connected failed : #{$!}\n#{$!.backtrace.join("\n")}"
            }
          end
          @state = :connected
        elsif stanza.name == "error" 
          raise AuthenticationError
        else
          raise
        end

      end
    end
    
    ##
    # Namespace of the component
    def stream_namespace
      'jabber:component:accept'
    end
    
    ##
    # Resolution for Components, based on SRV records
    def self.resolve(host, &block)
      Resolv::DNS.open { |dns|
        # If ruby version is too old and SRV is unknown, this will raise a NameError
        # which is caught below
        Skates.logger.debug {
          "RESOLVING: #{host} "
        }
        found = false
        records = dns.getresources(host, Resolv::DNS::Resource::IN::A)
        records.each do |record|
          ip = record.address.to_s
          if block.call({"host" => ip}) 
            found = true
            break
          end
        end
        block.call(false) unless found # bleh, we couldn't resolve to any valid. Too bad.
      }
    end
    
    private
    
    def handshake(stanza)
      hash = Digest::SHA1::hexdigest(stanza.attributes['id'].content + @password)
      doc = Nokogiri::XML::Document.new
      handshake = Nokogiri::XML::Node.new("handshake", doc)
      doc.add_child(handshake)
      handshake.content = hash
      handshake
    end
    
  end
end
