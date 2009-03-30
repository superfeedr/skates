module Babylon
  module Base
    # Class used to Parse a Message on the XMPP stream
    class Message < Stanza
      element :body
      element :message, :value => :to, :as => :to 
      element :message, :value => :from, :as => :from 
      element :message, :value => :id, :as => :stanza_id 
      element :message, :value => :type, :as => :stanza_type 
      element :message, :value => :"xml:lang", :as => :lang 
    end
  end
end