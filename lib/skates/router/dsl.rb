module Skates
  module Router
    ##
    # We use this class to assert the ordering of the router DSL
    class OutOfOrder < StandardError; end

    # Creates a simple DSL for stanza routing.
    class DSL
      attr_reader :routes

      def initialize
        @routes = []
      end

      # Match an xpath.
      def xpath(path, namespaces = {})
        @routes << {"xpath" => [path, namespaces]}
        self
      end

      # Set the priority of the last created route.
      def priority(n)
        route = @routes.last
        raise OutOfOrder unless route.is_a?(Route) # check that this is in the right order
        route.priority = n
        self
      end

      # Map a route to a specific controller and action.
      def to(params)
        last = @routes.pop
        last["controller"] = params[:controller]
        last["action"] = params[:action]
        # We now have all the properties we really need to create a route.
        @routes << Route.new(last)
        self
      end

      protected
      def disco_for(type, node = nil)
        str = "//iq[@type='get']/*[namespace(., 'query', 'http://jabber.org/protocol/disco##{type.to_s}')"
        str += " and @node = '#{node}'" if node
        str += "]"
        xpath(str)
      end
    end
  end
end
