## 
# Mock for EventMachine
module EventMachineMock
  def self.run(proc)
    proc.call
  end
  
  def self.epoll; end

  def self.stop_event_loop; end

end

##
EventMachine = EventMachineMock