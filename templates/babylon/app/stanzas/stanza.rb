class Stanza < Babylon::Base::Stanza 
  # element :pubsub (will match to the content of <pubsub> and define a .pubsub method)
  # element :publish, :as => :node, :value => :node (will match to the content of the "node" attribute of <publish> and defined a .node method)
  # elements :entry, :as => :entries, :class => AtomEntry (will match <entry> elements to a subclass AtomEntry (that you must define, using SaxMachine) and create a .entries.methods that returns an Array of AtomEntry.
end