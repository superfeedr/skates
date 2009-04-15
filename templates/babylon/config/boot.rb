require "rubygems"
require "babylon"
require File.dirname(__FILE__) + "/dependencies"

# Start the App
Babylon::Runner::run(ARGV[0] || "development") do
  # Run the initializers, too. This is done here since some initializers might need EventMachine to be started.
  Dir[File.join(File.dirname(__FILE__), '/initializers/*.rb')].each {|f| require f }
end
