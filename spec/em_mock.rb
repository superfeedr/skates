## 
# Mock for EventMachine
module EventMachine
  
  ##
  # Mock for the Connection Class
  class Connection
    def self.new(*args)
      allocate.instance_eval do
        # Call a superclass's #initialize if it has one
        initialize(*args)
        # Store signature and run #post_init
        post_init
        self
      end
    end
  end
  
  ##
  # Stub for run
  def self.run(proc)
    proc.call
  end
  
  ##
  # Stub for epoll
  def self.epoll; end

  ##
  # Stub! to stop the event loop.
  def self.stop_event_loop; end

  ##
  # Stub for connect (should return a connection object)
  def self.connect(host, port, handler, params)
    handler.new(params)
  end
  
end
