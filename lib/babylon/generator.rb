require "templater"

module Babylon
  module Generator
    extend Templater::Manifold
    
    desc <<-DESC
      Babylon is a framework to generate XMPP Applications in Ruby."
    DESC
    
    ##
    # Generates a Babylon Application
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
      empty_directory :views_directory do |d|
        d.destination = "#{application_name}/app/stanzas"
      end
      empty_directory :models_directory do |d|
        d.destination = "#{application_name}/app/models"
      end
      empty_directory :initializers_directory do |d|
        d.destination = "#{application_name}/config/initializers"
      end
      empty_directory :tmp_directory do |d|
        d.destination = "#{application_name}/tmp"
      end 
      empty_directory :log_directory do |d|
        d.destination = "#{application_name}/log"
      end
      empty_directory :pid_directory do |d|
        d.destination = "#{application_name}/tmp/pids"
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
      template :component_file do |f|
        f.source = "#{source_root}/script/component"
        f.destination = "#{application_name}/script/component"
      end
      
    end
    
    ##
    # Generates a new controller, with the corresponding stanzas and routes.
    class ControllerGenerator < Templater::Generator
      desc <<-DESC
        Generates a new controller for the current Application. It also adds the corresponding routes and actions, based on a Xpath and priority. \nSyntax: babylon controller <controller_name> [<action_name>:<priority>:<xpath>],[...]"
      DESC
      
      first_argument  :controller_name, :required => true,   :desc => "Name of the Controller."
      second_argument :actions_arg,      :required => true,  :as => :array,      :default => [], :desc => "Actions implemented by this controller. Use the following syntax : name:priority:xpath"
      
      def self.source_root
        File.join(File.dirname(__FILE__), '../../templates/babylon/app/controllers')
      end
      
      def controller_actions
        @controller_actions ||= actions_arg.map { |a| a.split(":") }
      end
      
      def controller_class_name
        "#{controller_name.capitalize}Controller"
      end
      
      ##
      # This is a hack since Templater doesn't offer any simple way to edit files right now...
      def add_route_for_actions_in_controller(actions, controller)
        sentinel = "Babylon::CentralRouter.draw do"
        router_path = "config/routes.rb"
        actions.each do |action|
          to_inject = "xpath(\"#{action[2]}\").to(:controller => \"#{controller}\", :action => \"#{action[0]}\").priority(#{action[1]})"
          if File.exist?(router_path)
            content = File.read(router_path).gsub(/(#{Regexp.escape(sentinel)})/mi){|match| "#{match}\n\t#{to_inject}"}
            File.open(router_path, 'wb') { |file| file.write(content) }
          end
        end
      end
      
      template :controller do |t|
        t.source = "#{source_root}/controller.rb"
        t.destination = "app/controllers/#{controller_name}_controller.rb"
        self.add_route_for_actions_in_controller(controller_actions, controller_name)
        # This is a hack since Templater doesn't offer any simple way to write several files from one...
        FileUtils.mkdir("app/views/#{controller_name}") unless File.exists?("app/views/#{controller_name}")
        controller_actions.each do |action|
          FileUtils.cp("#{source_root}/../views/view.rb", "app/views/#{controller_name}/#{action[0]}.xml.builder")
        end
        
        # And now, let's create the stanza files
        controller_actions.each do |action|
          FileUtils.cp("#{source_root}/../stanzas/stanza.rb", "app/stanzas/#{action[0]}.rb")
          # We need to replace 
          # "class Stanza < Babylon::Base::Stanza" with "class #{action[0]} < Babylon::Base::Stanza"
          content = File.read("app/stanzas/#{action[0]}.rb").gsub("class Stanza < Babylon::Base::Stanza", "class #{action[0].capitalize} < Babylon::Base::Stanza")
          File.open("app/stanzas/#{action[0]}.rb", 'wb') { |file| file.write(content) }
        end
      end
    end
    
    # The generators are added to the manifold, and assigned the names 'wiki' and 'blog'.
    # So you can call them <script name> blog merb-blog-in-10-minutes and
    # <script name> blog merb-wiki-in-10-minutes, respectively
    add :application, ApplicationGenerator
    add :controller, ControllerGenerator
    
  end
end
