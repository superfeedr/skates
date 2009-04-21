module Babylon
  ##
  # ComponentConnection is in charge of the XMPP connection itself.
  # Upon stanza reception, and depending on the status (connected... etc), this component will handle or forward the stanzas.
  class ComponentConnection < XmppConnection
    require 'digest/sha1'
    
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
      xml = Nokogiri::XML::Builder.new 
      xml.send('stream:stream', {'xmlns' => "jabber:component:accept", 'xmlns:stream' => 'http://etherx.jabber.org/streams', 'to' => jid}) do |stream|
        stream.paste_content_here #  The stream:stream element should be cut here ;)
      end
      start, stop = xml.to_xml.split('<paste_content_here/>')
      send_xml(start)
    end

    ##
    # XMPP Component handshake as defined in XEP-0114:
    # http://xmpp.org/extensions/xep-0114.html
    def receive_stanza(stanza)
      case @state
      when :connected # Most frequent case
          super # Can be dispatched
          
      when :wait_for_stream
        if stanza.name == "stream:stream" && stanza.attributes['id']
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
            Babylon.logger.error("on_connected failed : #{$!}\n#{$!.backtrace.join("\n")}")
          end
          @state = :connected
        elsif stanza.name == "stream:error"
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
    
    private
    
    def handshake(stanza)
      hash = Digest::SHA1::hexdigest(stanza.attributes['id'].content + @password)
      handshake = Nokogiri::XML::Node.new("handshake", stanza.document)
      handshake.content = hash
      handshake
    end
    
    
  end
end
