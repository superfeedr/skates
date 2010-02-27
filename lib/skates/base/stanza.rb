module Skates
  module Base
    ##
    # Class used to Parse a Stanza on the XMPP stream.
    # You should have a Stanza subsclass for each of your controller actions, as they allow you to define which stanzas and which information is passed to yoru controllers.
    # These classes extend the Nokogiri::XML::Node
    # You can define your own accessors to access the content uou need, using XPath.
    
    # if your stanza is a message stanza, you can match the following for example:
    # element :message, :value => :to, :as => :to 
    # element :message, :value => :from, :as => :from 
    # element :message, :value => :id, :as => :stanza_id 
    # element :message, :value => :type, :as => :stanza_type 
    # element :message, :value => :"xml:lang", :as => :lang 
    #
    class Stanza 
      
      def initialize(node)
        @node = node
      end
      
      def from
        @node.at_xpath(".")["from"]
      end
      
      def to
        @node.at_xpath(".")["to"]
      end
      
      def id
        @node.at_xpath(".")["id"]
      end
      
      def type
        @node.at_xpath(".")["type"]
      end
      
      def name
        @node.at_xpath(".").name
      end
      
    end
  end
end