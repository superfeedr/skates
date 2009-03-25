require "rubygems"
require "spec"

# gem install redgreen for colored test output
begin require "redgreen" unless ENV['TM_CURRENT_LINE']; rescue LoadError; end

path = File.expand_path(File.dirname(__FILE__) + "/../lib/")
$LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)

require File.dirname(__FILE__) + "/../lib/babylon" unless defined? Babylon

# #
# Deactivate the logging
Babylon.logger.level = Log4r::FATAL

Babylon.environment = "test"

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
      mock(Object, 
      { 
        :on_connected => Proc.new { |conn|
          # Connected
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

# Stub for EventMachineConnection
module EventMachine

  def EventMachine.stop_event_loop
    # Do nothing
  end

  def EventMachine.connect(host, port, handler, params)
    klass = if (handler and handler.is_a?(Class))
      raise ArgumentError, 'must provide module or subclass of EventMachine::Connection' unless Connection > handler
      handler
    else
      Class.new( Connection ) {handler and include handler}
    end
    c = klass.new nil, params
  end
end
