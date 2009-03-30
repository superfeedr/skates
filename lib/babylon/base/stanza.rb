require "sax-machine"

module Babylon
  module Base
    # Class used to Parse a Presence on the XMPP stream
    class Stanza
      
      attr_reader :xml      
      include SAXMachine
      
      def initialize(xml = nil)
        @xml = xml
        parse("#{xml}")
      end
      
    end
  end
end