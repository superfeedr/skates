module Babylon

  ##
  # ClientConnection is in charge of the XMPP connection for a Regular XMPP Client.
  # So far, SASL Plain authenticationonly is supported
  # Upon stanza reception, and depending on the status (connected... etc), this component will handle or forward the stanzas.
  class ClientConnection < XmppConnection
    require 'digest/sha1'
    require 'base64'
    require 'resolv'

    attr_reader :binding_iq_id, :session_iq_id

    ##
    # Creates a new ClientConnection and waits for data in the stream
    def initialize(params)
      super(params)
      @state = :wait_for_stream
    end

    ##
    # Connects the ClientConnection based on SRV records for the jid's domain, if no host or port has been specified.
    # In any case, we give priority to the specified host and port.
    def self.connect(params, handler = nil)
      return super(params, handler) if params["host"] && params["port"]

      begin
        begin
          srv = []
          Resolv::DNS.open { |dns|
            # If ruby version is too old and SRV is unknown, this will raise a NameError
            # which is caught below
            host_from_jid = params["jid"].split("/").first.split("@").last
            Babylon.logger.debug("RESOLVING: _xmpp-client._tcp.#{host_from_jid} (SRV)")
            srv = dns.getresources("_xmpp-client._tcp.#{host_from_jid}", Resolv::DNS::Resource::IN::SRV)
          }
          # Sort SRV records: lowest priority first, highest weight first
          srv.sort! { |a,b| (a.priority != b.priority) ? (a.priority <=> b.priority) : (b.weight <=> a.weight) }
          # And now, for each record, let's try to connect.
          srv.each { |record|
            begin
              params["host"] = record.target.to_s
              params["port"] = Integer(record.port)
              super(params, handler)
              # Success
              break
            rescue SocketError, Errno::ECONNREFUSED
              # Try next SRV record
            end
          }
        rescue NameError
          Babylon.logger.debug "Resolv::DNS does not support SRV records. Please upgrade to ruby-1.8.3 or later! \n#{$!} : #{$!.backtrace.join("\n")}"
        end
      end
    end

    def stream_stanza
      doc = Nokogiri::XML::Document.new
      stream = Nokogiri::XML::Node.new("stream", doc)
      doc.add_child(stream)
      stream.add_namespace(nil, stream_namespace())
      stream.add_namespace("stream", "http://etherx.jabber.org/streams")
      stream["to"] = jid.split("/").first.split("@").last
      stream["version"] = "1.0"
      paste_content_here = Nokogiri::XML::Node.new("paste_content_here", doc)
      stream.add_child(paste_content_here)
      doc.to_xml.split('<stream:paste_content_here/>').first
    end

    ##
    # Connection_completed is called when the connection (socket) has been established and is in charge of "building" the XML stream 
    # to establish the XMPP connection itself.
    # We use a "tweak" here to send only the starting tag of stream:stream
    def connection_completed
      super
      send_xml(stream_stanza)
    end

    ##
    # Called upon stanza reception
    # Marked as connected when the client has been SASLed, authenticated, biund to a resource and when the session has been created
    def receive_stanza(stanza)
      begin
        case @state
        when :connected
          super # Can be dispatched

        when :wait_for_stream_authenticated
          if stanza.name == "stream:stream" && stanza.attributes['id']
            @state = :wait_for_bind
          end

        when :wait_for_stream
          if stanza.name == "stream:stream" && stanza.attributes['id']
            @state = :wait_for_auth_mechanisms
          end

        when :wait_for_auth_mechanisms
          if stanza.name == "stream:features"
            if stanza.at("startls") # we shall start tls
              doc = Nokogiri::XML::Document.new
              starttls = Nokogiri::XML::Node.new("starttls", doc)
              doc.add_child(starttls)
              starttls.add_namespace(nil, "urn:ietf:params:xml:ns:xmpp-tls")
              send_xml(starttls)
              @state = :wait_for_proceed
            elsif stanza.at("mechanisms") # tls is ok
              if stanza.at("mechanisms").children.map() { |m| m.text }.include? "PLAIN"
                doc = Nokogiri::XML::Document.new
                auth = Nokogiri::XML::Node.new("auth", doc)
                doc.add_child(auth)
                auth['mechanism'] = "PLAIN"
                auth.add_namespace(nil, "urn:ietf:params:xml:ns:xmpp-sasl")
                auth.content = Base64::encode64([jid, jid.split("@").first, @password].join("\000")).gsub(/\s/, '')
                send_xml(auth)
                @state = :wait_for_success
              end
            end
          end

        when :wait_for_success
          if stanza.name == "success" # Yay! Success
            @state = :wait_for_stream_authenticated
            @parser.reset
            send_xml(stream_stanza)
          elsif stanza.name == "failure"
            if stanza.at("bad-auth") || stanza.at("not-authorized")
              raise AuthenticationError
            else
            end
          else
            # Hum Failure...
          end

        when :wait_for_bind
          if stanza.name == "stream:features"
            if stanza.at("bind")
              doc = Nokogiri::XML::Document.new
              # Let's build the binding_iq
              @binding_iq_id = Integer(rand(10000))
              iq = Nokogiri::XML::Node.new("iq", doc)
              doc.add_child(iq)
              iq["type"] = "set"
              iq["id"] = "#{@binding_iq_id}"
              bind = Nokogiri::XML::Node.new("bind", doc)
              bind.add_namespace(nil, "urn:ietf:params:xml:ns:xmpp-bind")
              iq.add_child(bind)
              resource = Nokogiri::XML::Node.new("resource", doc)
              if jid.split("/").size == 2 
                resource.content = (@jid.split("/").last)
              else
                resource.content = "babylon_client_#{binding_iq_id}"
              end
              bind.add_child(resource)
              send_xml(iq)
              @state = :wait_for_confirmed_binding
            end
          end

        when :wait_for_confirmed_binding
          if stanza.name == "iq" && stanza["type"] == "result" && Integer(stanza["id"]) ==  @binding_iq_id
            if stanza.at("jid")
              jid = stanza.at("jid").text
            end
          end
          # And now, we must initiate the session
          @session_iq_id = Integer(rand(10000))
          doc = Nokogiri::XML::Document.new
          iq = Nokogiri::XML::Node.new("iq", doc)
          doc.add_child(iq)
          iq["type"] = "set"
          iq["id"] = "#{@session_iq_id}"
          session = Nokogiri::XML::Node.new("session", doc)
          session.add_namespace(nil, "urn:ietf:params:xml:ns:xmpp-session")
          iq.add_child(session)
          send_xml(iq)
          @state = :wait_for_confirmed_session

        when :wait_for_confirmed_session
          if stanza.name == "iq" && stanza["type"] == "result" && Integer(stanza["id"]) ==  @session_iq_id && stanza.at("session")
            # And now, send a presence!
            doc = Nokogiri::XML::Document.new
            presence = Nokogiri::XML::Node.new("presence", doc)
            send_xml(presence)
            begin
              @handler.on_connected(self) if @handler and @handler.respond_to?("on_connected")
            rescue
              Babylon.logger.error("on_connected failed : #{$!}\n#{$!.backtrace.join("\n")}")
            end
            @state = :connected
          end

        when :wait_for_proceed
          start_tls() # starting TLS
          @state = :wait_for_stream
          @parser.reset
          send_xml stream_stanza
        end
      rescue
        Babylon.logger.error("#{$!}:\n#{$!.backtrace.join("\n")}")
      end
    end

    ##
    # Namespace of the client
    def stream_namespace
      "jabber:client"
    end

  end
end
