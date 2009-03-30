require "templater"

module Babylon
  module Generator
    extend Templater::Manifold

    class ApplicationGenerator < Templater::Generator

      first_argument :app_name, :required => true, :desc => "Your application name."

      def self.source_root
        File.join(File.dirname(__FILE__), '../../templates/babylon')
      end

      def self.application_name
        app_name 
      end

      directory application_name
    end

    class ControllerGenerator < Templater::Generator
      def self.source_root
        File.join(File.dirname(__FILE__), '../../templates/controller')
      end
    end


    # The generators are added to the manifold, and assigned the names 'wiki' and 'blog'.
    # So you can call them <script name> blog merb-blog-in-10-minutes and
    # <script name> blog merb-wiki-in-10-minutes, respectively
    add :application, ApplicationGenerator
    add :controller, ControllerGenerator

  end
end
