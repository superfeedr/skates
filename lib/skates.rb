$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'eventmachine'
require 'log4r'
require 'nokogiri'
require 'yaml'
require 'fileutils'
require 'sax-machine'
require 'digest/sha1'
require 'base64'
require 'resolv'
require 'templater'
require 'cgi'
require 'utf8cleaner'

require 'skates/ext/array.rb'
require 'skates/xmpp_connection'
require 'skates/xmpp_parser'
require 'skates/component_connection'
require 'skates/client_connection'
require 'skates/router'
require 'skates/runner'
require 'skates/generator'
require 'skates/base/controller'
require 'skates/base/view'
require 'skates/base/stanza'

# Skates is a XMPP Component Framework based on EventMachine. It uses the Nokogiri GEM, which is a Ruby wrapper for Libxml2.
# It implements the MVC paradigm.
# You can create your own application by running :
#   $> skates app_name
# This will generate some folders and files for your application. Please see README.rdoc for further instructions

module Skates

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
      reopen_logs
    end
    @@logger
  end
  
  ##
  # Re-opens the logs
  # In "development" environment, the log will be on stdout
  def self.reopen_logs
    # Open a new logger
    logger = Log4r::Logger.new("Skates") 
    logger.add(Log4r::Outputter.stdout) if Skates.environment == "development"
    log_file = Log4r::RollingFileOutputter.new("#{Skates.environment}", :filename => "log/#{Skates.environment}.log", :trunc => false)
    case Skates.environment
    when "production"
      log_file.formatter = Log4r::PatternFormatter.new(:pattern => "%d (#{Process.pid}) [%l] :: %m", :date_pattern => "%d/%m %H:%M")      
    when "development"
      log_file.formatter = Log4r::PatternFormatter.new(:pattern => "%d (#{Process.pid}) [%l] :: %m", :date_pattern => "%d/%m %H:%M")      
    else
      log_file.formatter = Log4r::PatternFormatter.new(:pattern => "%d (#{Process.pid}) [%l] :: %m", :date_pattern => "%d/%m %H:%M")      
    end
    logger.add(log_file)
    # Set up the variable.
    @@logger = logger
  end

  ##
  # Set the configuration file for this component.
  def self.config_file=(file)
		@@config_file = file
  end

  ##
  # Return the configuration file for this component.
  def self.config_file
		@@config_file
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
    CGI.unescapeHTML(str)
  end
  
end

