module Babylon
  module Base
    # Class used to Parse an IQ on the XMPP stream
    class Iq < Stanza
      element :iq, :value => :to, :as => :to 
      element :iq, :value => :from, :as => :from 
      element :iq, :value => :id, :as => :stanza_id 
      element :iq, :value => :type, :as => :stanza_type 
      element :iq, :value => :"xml:lang", :as => :lang 
    end
  end
end