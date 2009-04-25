require File.dirname(__FILE__)+"/router/dsl"

module Babylon
  ##
  # Routers are in charge of sending the right stanzas to the right controllers based on user defined Routes.
  # Each application can have only one!
  class StanzaRouter
    
    attr_reader :routes, :connection
    
    def initialize
      @routes = []
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
      return false if !@connection 
      
      route = routes.select{ |r| r.accepts?(xml_stanza) }.first 
      
      return false unless route 
      
      Babylon.logger.info("ROUTING TO #{route.controller}::#{route.action}") 
      
      begin 
        stanza = Kernel.const_get(route.action.capitalize).new(xml_stanza) 
      rescue 
        Babylon.logger.error("STANZA COULDN'T BE INSTANTIATED : #{$!.class} => #{$!}") 
      end 
      controller = route.controller.new(stanza) 
      begin 
        controller.perform(route.action) 
        connection.send_xml(controller.evaluate) 
      rescue 
        Babylon.logger.error("#{$!.class} => #{$!} IN #{route.controller}::#{route.action}\n#{$!.backtrace.join("\n")}") 
      end 
    end 
    
    # Throw away all added routes from this router. Helpful for 
    # testing. 
    def purge_routes! 
      @routes = [] 
    end 
    
    # Run the router DSL. 
    def draw(&block) 
      r = Router::DSL.new 
      r.instance_eval(&block) 
      r.routes.each do |route| 
        raise("Route lacks destination: #{route.inspect}") unless route.is_a?(Route) 
      end 
      @routes += r.routes 
      sort
    end

    private
    def sort
      @routes.sort! { |r1,r2|
        r2.priority <=> r1.priority
      }
    end
  end

  ##
  # Route class which associate an XPATH match and a priority to a controller and an action
  class Route

    attr_accessor :priority, :controller, :action, :xpath
    
    ##
    # Creates a new route
    def initialize(params)
      raise("No controller given for route") unless params["controller"]
      raise("No action given for route") unless params["action"]
      @priority   = params["priority"] || 0
      # For the xpath, we actually need to add the "stream" namespace by default.
      @xpath      = params["xpath"] if params["xpath"]
      @css        = params["css"] if params["css"]
      @controller = Kernel.const_get("#{params["controller"].capitalize}Controller")
      @action     = params["action"]
    end

    ##
    # Checks that the route matches the stanzas and calls the the action on the controller
    def accepts?(stanza)
      if @xpath
        stanza.xpath(@xpath, XpathHelper.new).first ? self : false
      elsif @css
        stanza.css(@css).first ? self : false
      end
    end
    
  end
  
end
