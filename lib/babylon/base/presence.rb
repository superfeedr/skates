module Babylon
  module Base
    class Presence < Stanza
      element :presence, :value => :to, :as => :to 
      element :presence, :value => :from, :as => :from 
      element :presence, :value => :id, :as => :stanza_id 
      element :presence, :value => :type, :as => :stanza_type 
      element :presence, :value => :"xml:lang", :as => :lang
    end
  end
end