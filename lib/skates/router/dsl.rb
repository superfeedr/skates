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
      def xpath(path)
        @routes << {"xpath" => path}
        self
      end

      # Set the priority of the last created route.
      def priority(n)
        route = @routes.last
        raise OutOfOrder unless route.is_a?(Route) # check that this is in the right order
        route.priority = n
        self
      end

      # Match a disco_info query.
      def disco_info(node = nil)
        disco_for(:info, node)
      end

      # Match a disco_items query.
      def disco_items(node = nil)
        disco_for(:items, node)
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
