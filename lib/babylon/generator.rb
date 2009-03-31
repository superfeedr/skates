require "templater"

module Babylon
  module Generator
    extend Templater::Manifold
    
    desc <<-DESC
      Babylon is a framework to generate XMPP Applications in Ruby."
    DESC
    
    class ApplicationGenerator < Templater::Generator
      desc <<-DESC
        Generates the file architecture for a Babylon Application. To run, you MUST provide an application name"
      DESC
      
      first_argument :application_name, :required => true, :desc => "Your application name."
      
      def self.source_root
        File.join(File.dirname(__FILE__), '../../templates/babylon')
      end
      
      # Create all subsdirectories
      empty_directory :app_directory do |d|
        d.destination = "#{application_name}/app"
      end
      empty_directory :controllers_directory do |d|
        d.destination = "#{application_name}/app/controllers"
      end
      empty_directory :views_directory do |d|
        d.destination = "#{application_name}/app/views"
      end
      empty_directory :models_directory do |d|
        d.destination = "#{application_name}/app/models"
      end
      empty_directory :initializers_directory do |d|
        d.destination = "#{application_name}/config/initializers"
      end
      
      # And now add the critical files
      file :boot_file do |f|
        f.source = "#{source_root}/config/boot.rb"
        f.destination = "#{application_name}/config/boot.rb"
      end
      file :config_file do |f|
        f.source = "#{source_root}/config/config.yaml"
        f.destination = "#{application_name}/config/config.yaml"
      end
      file :dependencies_file do |f|
        f.source = "#{source_root}/config/dependencies.rb"
        f.destination = "#{application_name}/config/dependencies.rb"
      end
      file :dependencies_file do |f|
        f.source = "#{source_root}/config/routes.rb"
        f.destination = "#{application_name}/config/routes.rb"
      end
      file :component_file do |f|
        f.source = "#{source_root}/script/component"
        f.destination = "#{application_name}/script/component"
      end
      
    end
    
    class ControllerGenerator < Templater::Generator
      desc <<-DESC
        Generates a new controller for the current Application. It also adds the corresponding routes and actions, based on a Xpath and priority. \nSyntax: babylon controller <controller_name> [<action_name>:<priority>:<xpath>]"
      DESC
      
      first_argument  :controller_name, :required => true,  :desc => "Name of the Controller."
      second_argument :actions_arg,     :as => :array,      :default => [], :desc => "Actions implemented by this controller. Use the following syntax : name:priority:xpath"
      
      def self.source_root
        File.join(File.dirname(__FILE__), '../../templates/babylon/app/controllers')
      end
      
      def controller_actions
        @controller_actions ||= actions_arg.map { |a| a.split(":") }
      end
      
      def controller_class_name
        "#{controller_name.capitalize}Controller"
      end
      
      template :controller do |t|
        puts actions_arg.inspect
        t.source = "#{source_root}/controller.rb"
        t.destination = "app/controllers/#{controller_name}_controller.rb"
      end
    end
    
    # The generators are added to the manifold, and assigned the names 'wiki' and 'blog'.
    # So you can call them <script name> blog merb-blog-in-10-minutes and
    # <script name> blog merb-wiki-in-10-minutes, respectively
    add :application, ApplicationGenerator
    add :controller, ControllerGenerator
    
  end
end
