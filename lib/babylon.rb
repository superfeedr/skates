$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'eventmachine'
require 'log4r'
require 'nokogiri'
require 'yaml'
require 'fileutils'
require 'sax-machine'

require 'babylon/xmpp_connection'
require 'babylon/xmpp_parser'
require 'babylon/component_connection'
require 'babylon/client_connection'
require 'babylon/router'
require 'babylon/runner'
require 'babylon/generator'
require "babylon/xpath_helper"
require 'babylon/base/controller'
require 'babylon/base/view'
require 'babylon/base/stanza'

# Babylon is a XMPP Component Framework based on EventMachine. It uses the Nokogiri GEM, which is a Ruby wrapper for Libxml2.
# It implements the MVC paradigm.
# You can create your own application by running :
#   $> babylon app_name
# This will generate some folders and files for your application. Please see README.rdoc for further instructions

module Babylon

  def self.environment=(_env)
    @@env = _env
  end

  def self.environment
    unless self.class_variable_defined?("@@env")
      @@env = "development"
    end
    @@env
  end
  
  ##
  # Sets up the router
  def self.router=(router)
    @@router = router
  end
  
  ##
  # Retruns the router
  def self.router
    unless self.class_variable_defined?("@@router")
      @@router = nil
    end
    @@router
  end
  
  ##
  # Caches the view files to improve performance.  
  def self.cache_views
    @@views= {}
    Dir.glob('app/views/*/*').each do |f|
      @@views[f] = File.read(f)
    end        
  end
  
  def self.views
    unless self.class_variable_defined?("@@views")
      @@views= {}
    end
    @@views
  end

  ##
  # Returns a shared logger for this component.
  def self.logger
    unless self.class_variable_defined?("@@logger")
      @@logger = Log4r::Logger.new("BABYLON")
      @@logger.add(Log4r::Outputter.stdout) if Babylon.environment == "development"
    end
    @@logger
  end

  ##
  # Set the configuration for this component.
  def self.config=(conf)
    @@config = conf
  end

  ##
  # Return the configuration for this component.
  def self.config
    @@config
  end
  
  ##
  # Decodes XML special characters.
  def self.decode_xml(str)
    entities = {
      'lt'    => '<',
      'gt'    => '>',
      '#38'   => '&',
      'amp'   => '&',
      'quot'  => '"',
      '#13'   => "\r",
    } 
    entities.keys.inject(str) { |string, key|
      string.gsub(/&#{key};/, entities[key])
    } 
  end
  
end

