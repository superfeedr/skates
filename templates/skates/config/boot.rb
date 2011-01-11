##
# This file is run by the dameons, in the apps directory

# Change directory to the app's directory.
Dir.chdir(File.dirname(__FILE__) + "/../") 

Bundler.require(:default)
require File.dirname(__FILE__) + "/dependencies"

Skates.config_file = 'config/config.yaml'

# Start the App
Skates::Runner::run(SKATES_ENV || "development") do
  # Run the initializers, too. This is done here since some initializers might need EventMachine to be started.
  Dir.glob('config/initializers/*.rb').each { |f| require f }
end
# Run the destructors, too. They're called when the app exits.
Dir.glob('config/destructors/*.rb').each { |f| require f }
