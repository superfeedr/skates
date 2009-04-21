require File.dirname(__FILE__)+"/router/dsl"

module Babylon
  ##
  # Routers are in charge of sending the right stanzas to the right controllers based on user defined Routes.
  # Each application can have only one!
  class StanzaRouter
    
    attr_reader :routes, :connection, :namespaces
    
    DEFAULT_NAMESPACES =
      {
        'disco_info'  => 'http://jabber.org/protocol/disco#info',
        'disco_items' => 'http://jabber.org/protocol/disco#items',
        'muc'         => 'http://jabber.org/protocol/muc',
        'muc_admin'   => 'http://jabber.org/protocol/muc#admin'
      }

    def initialize
      @routes = []
      @namespaces = DEFAULT_NAMESPACES
    end
    
    ##
    # Connected is called by the XmppConnection to indicate that the XMPP connection has been established
    def connected(connection)
      @connection = connection
    end
    
    ##
    # Look for the first matching route and calls the corresponding action for the corresponding controller.
    # Sends the response on the XMPP stream/ 
    def route(xml_stanza) 
      route = routes.detect { |r| r.accepts?(xml_stanza) }
      return false unless route 
      execute_route(route.controller, route.action, xml_stanza)
    end 
    
    ##
    # Executes the route for the given xml_stanza, by instantiating the controller_name, calling action_name and sending 
    # the result to the connection
    def execute_route(controller_name, action_name, xml_stanza = nil)
      Babylon.logger.info("ROUTING TO #{controller_name}::#{action_name}") 
      stanza = nil
      stanza = Kernel.const_get(action_name.capitalize).new(xml_stanza) if xml_stanza
      controller = controller_name.new(stanza) 
      controller.perform(action_name) 
      connection.send_xml(controller.evaluate)
    end
    
    ##
    # Throw away all added routes from this router. Helpful for 
    # testing. 
    def purge_routes! 
      @routes = [] 
    end 
    
    ##
    # Run the router DSL. 
    def draw(&block) 
      dsl = Router::DSL.new 
      dsl.instance_eval(&block) 
      dsl.routes.each do |route| 
        raise("Route lacks destination: #{route.inspect}") unless route.is_a?(Route) 
      end 
      @routes += dsl.routes 
      @namespaces.merge!(dsl.namespaces)
      sort
      @routes.each {|route| route.router = self }
    end

    private
    
    def sort
      @routes.sort! { |r1,r2| r2.priority <=> r1.priority }
    end
  end

  ##
  # Route class which associate an XPATH match and a priority to a controller and an action
  class Route
    attr_accessor :priority, :controller, :action, :xpath, :router
    
    ##
    # Creates a new route
    def initialize(params)
      raise("No controller given for route") unless params["controller"]
      raise("No action given for route") unless params["action"]
      raise("No xpath given for route") unless params["xpath"]
      @priority   = params["priority"] || 0
      @xpath      = params["xpath"] 
      @controller = Kernel.const_get("#{params["controller"].capitalize}Controller")
      @action     = params["action"]
    end
    
    ##
    # Checks that the route matches the stanzas and calls the the action on the controller.
    def accepts?(stanza)
      stanza.xpath(@xpath, router.namespaces).empty?
    end
    
  end
  
end
