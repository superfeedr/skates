require 'templater'

require File.dirname(__FILE__) + "/../lib/skates"
require File.dirname(__FILE__) + "/../lib/skates/generator"

# #
# Deactivate the logging
Skates.logger.level = Log4r::FATAL

Skates.environment = "test"

if !defined? SkatesSpecHelper
  module SkatesSpecHelper
    ##
    # Load configuration from a local config file
    def skates_config
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