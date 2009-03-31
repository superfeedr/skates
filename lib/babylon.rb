$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'eventmachine'
require 'log4r'
require 'nokogiri'
require 'yaml'
require 'fileutils'

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
require 'babylon/base/message'
require 'babylon/base/iq'
require 'babylon/base/presence'

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
  # Caches the view files to improve performance.  
  def self.cache_views
    @@cached_views= {}
    Dir.glob('app/views/*/*').each do |f|
      @@cached_views[f] = File.read(f)
    end        
  end
  
  def self.cached_views
    unless self.class_variable_defined?("@@cached_views")
      @@cached_views= {}
    end
    @@cached_views
  end

  ##
  # Returns a shared logger for this component.
  def self.logger
    unless self.class_variable_defined?("@@logger")
      @@logger = Log4r::Logger.new("BABYLON")
      @@logger.add(Log4r::Outputter.stderr)
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
  
end

