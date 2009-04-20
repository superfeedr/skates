##
# This file is run by the dameons, in the apps directory

# Change directory to the app's directory.
Dir.chdir(File.dirname(__FILE__) + "/../") 

require "rubygems"
require "babylon"
require File.dirname(__FILE__) + "/dependencies"


# Start the App
Babylon::Runner::run(ARGV[0] || "development") do
  # Run the initializers, too. This is done here since some initializers might need EventMachine to be started.
  Dir.glob('config/initializers/*.rb').each { |f| require f }
end