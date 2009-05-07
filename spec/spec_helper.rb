require File.dirname(__FILE__) + "/../lib/babylon"

# #
# Deactivate the logging
Babylon.logger.level = Log4r::FATAL

Babylon.environment = "test"

if !defined? BabylonSpecHelper
  module BabylonSpecHelper
    ##
    # Load configuration from a local config file
    def babylon_config
      @config ||= YAML.load(File.read(File.join(File.dirname(__FILE__), "config.yaml")))
    end

    ##
    # Mock for Handler
    def handler_mock
      @handler_mock ||= 
      begin
        mock(Object, { :on_connected => Proc.new { |conn|
          },
        :on_disconnected => Proc.new {
          # Disconnected
          },
        :on_stanza => Proc.new { |stanza|
          # Stanza!
          }
        })
      end
    end
  end
end