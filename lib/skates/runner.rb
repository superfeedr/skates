module Skates
  
  ##
  # Runner is in charge of running the application.
  class Runner
    
    PHI = ((1+Math.sqrt(5))/2.0)
    
    ## 
    # Prepares the Application to run.
    def self.prepare(env)
      # Load the configuration
      config_file = File.open('config/config.yaml')
      Skates.config = YAML.load(config_file)[Skates.environment]
      
      Skates.reopen_logs
      
      # Requiring all models, stanza, controllers
      ['app/models/*.rb', 'app/stanzas/*.rb', 'app/controllers/*_controller.rb'].each do |dir|
        Runner.require_directory(dir)
      end
      
      # Create the router
      Skates.router = Skates::StanzaRouter.new
      
      # Evaluate routes defined with the new DSL router.
      require 'config/routes.rb'
            
      # Caching views
      Skates.cache_views
      
      #Setting failed connection attemts
      @failed_connections = 0
      
    end
    
    ##
    # Convenience method to require files in a given directory
    def self.require_directory(path)
      Dir.glob(path).each { |f| require f }
    end
    
    ##
    # When run is called, it loads the configuration, the routes and add them into the router
    # It then loads the models.
    # Finally it starts the EventMachine and connect the ComponentConnection
    # You can pass an additional block that will be called upon launching, when the eventmachine has been started.
    def self.run(env)
      
      Skates.environment = env
      
      # Starting the EventMachine
      EventMachine.epoll
      EventMachine.run do
        
        Runner.prepare(env)
        
        case Skates.config["application_type"] 
        when "client"
          Skates::ClientConnection.connect(Skates.config, self) 
        else # By default, we assume it's a component
          Skates::ComponentConnection.connect(Skates.config, self) 
        end
        
        # And finally, let's allow the application to do all it wants to do after we started the EventMachine!
        yield(self) if block_given?
      end
    end
    
    ##
    # Returns the list of connection observers
    def self.connection_observers()
      @@observers ||= Array.new
    end
    
    ##
    # Adding a connection observer. These observer will receive on_connected and on_disconnected events.
    def self.add_connection_observer(observer)
      @@observers ||= Array.new 
      if observer.ancestors.include? Skates::Base::Controller
        Skates.logger.debug {
          "Added #{observer} to the list of Connection Observers"
        }
        @@observers.push(observer) unless @@observers.include? observer
      else
        Skates.logger.error {
          "Observer can only be Skates::Base::Controller"
        }
        false
      end
    end
    
    ## 
    # Will be called by the connection class once it is connected to the server.
    # It "plugs" the router and then calls on_connected on the various observers.
    def self.on_connected(connection)
      Skates.router.connected(connection)
      connection_observers.each do |observer|
        Skates.router.execute_route(observer, "on_connected")
      end
      
      # Connected so reset failed connection attempts
      @failed_connections = 0
    end
    
    ##
    # Will be called by the connection class upon disconnection.
    # It stops the event loop and then calls on_disconnected on the various observers.
    def self.on_disconnected()
      connection_observers.each do |conn_obs|
        observer = conn_obs.new
        observer.on_disconnected if observer.respond_to?("on_disconnected")
      end
      
      # Increment failed connection attempts and calculate time to next re-connect
      @failed_connections += 1
      reconnect_in = fib(@failed_connections)
      

      EventMachine.add_timer( reconnect_in ) {reconnect}
      
	  Skates.logger.error {
	   	"Disconnected - trying to reconnect in #{reconnect_in} seconds."
	  }
        
    end
    
    ##
    # Will be called by the connection class when it receives and parses a stanza.
    def self.on_stanza(stanza)
      begin
        Skates.router.route(stanza)
      rescue Skates::NotConnected
        Skates.logger.fatal {
          "#{$!.class} => #{$!.inspect}\n#{$!.backtrace.join("\n")}"
        }
        EventMachine::stop_event_loop
      rescue
        Skates.logger.error {
          "#{$!.class} => #{$!.inspect}\n#{$!.backtrace.join("\n")}"
        }
      end
    end
    
    def self.reconnect

		#Try to reconnect
		case Skates.config["application_type"] 
		    when "client"
		      Skates::ClientConnection.connect(Skates.config, self) 
			else # By default, we assume it's a component
		      Skates::ComponentConnection.connect(Skates.config, self) 
		end
    end
    
	def self.fib(n)
  		(Skates::Runner::PHI**n).round
	end
    
  end
end
