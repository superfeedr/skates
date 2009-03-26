module Babylon
  
  ##
  # Runner is in charge of running the application.
  class Runner
    
    ##
    # When run is called, it loads the configuration, the routes and add them into the router
    # It then loads the models.
    # Finally it starts the EventMachine and connect the ComponentConnection
    # You can pass an additional block that will be called upon launching, when the eventmachine has been started.
    def self.run(env)
      
      Babylon.environment = env
      
      # Starting the EventMachine
      EventMachine.epoll
      EventMachine.run do
        
        # Requiring all models
        Dir.glob('app/models/*.rb').each { |f| require f }

        # Load the controllers
        Dir.glob('app/controllers/*_controller.rb').each {|f| require f }

        #  Evaluate routes defined with the new DSL router.
        CentralRouter.draw do
          eval File.read("config/routes.rb")
        end
        
        config_file = File.open('config/config.yaml')
        
        # Caching views in production mode.
        if Babylon.environment == "production"
          Babylon.cache_views
        end
        
        Babylon.config = YAML.load(config_file)[Babylon.environment] 
        
        case Babylon.config["application_type"] 
          when "client"
            Babylon::ClientConnection.connect(Babylon.config, self) 
          else # By default, we assume it's a component
            Babylon::ComponentConnection.connect(Babylon.config, self) 
        end
        
        # And finally, let's allow the application to do all it wants to do after we started the EventMachine!
        yield if block_given?
      end
    end
    
    ## 
    # Will be called by the connection class once it is connected to the server.
    def self.on_connected(connection)
      Babylon::CentralRouter.connected(connection)
    end
    
    ##
    # Will be called by the connection class upon disconnection.
    def self.on_disconnected()
      EventMachine.stop_event_loop
    end
    
    ##
    # Will be called by the connection class when it receives and parses a stanza.
    def self.on_stanza(stanza)
      Babylon::CentralRouter.route(stanza)
    end
    
  end
end
