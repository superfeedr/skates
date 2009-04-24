module Babylon
  module Base
    
    ##
    # Your application's controller should be descendant of this class.
    class Controller
      
      attr_accessor :stanza, :rendered, :action_name # Stanza received by the controller (Nokogiri::XML::Node)
      
      ##
      # Creates a new controller (you should not override this class) and assigns the stanza as well as any other value of the hash to instances named after the keys of the hash.
      def initialize(stanza = nil)
        @stanza = stanza
        @view = nil
      end
      
      ##
      # Performs the action and calls back the optional block argument : you should not override this function
      def perform(action)
        @action_name = action
        begin
          self.send(@action_name)
        rescue
          Babylon.logger.error("#{$!}:\n#{$!.backtrace.join("\n")}")
        end
        self.render
      end
      
      ##
      # Returns the list of variables assigned during the action.
      def assigns
        vars = Hash.new
        instance_variables.each do |var|
          if !["@view", "@action_name", "@block"].include? var
            vars[var[1..-1]] = instance_variable_get(var)
          end
        end
        vars
      end
      
      ##
      # Called by default after each action to "build" a XMPP stanza. By default, it will use the /controller_name/action.xml.builder
      # You can use the following options :
      #   - :file : render a specific file (can be in a different controller)
      #   - :action : render another action of the current controller
      #   - :nothing : doesn't render anything
      def render(options = nil) 
        return if @view # Avoid double rendering, if we have already attached a view
        
        if options.nil? # default rendering
          result = render(:file => default_template_name)
        elsif options[:file]
          file = options[:file]
          if file =~ /^\// # Render from view root
            result = render_for_file(File.join("app", "views", "#{file}.xml.builder"))
          else
            result = render_for_file(view_path(file)) 
          end
        elsif action_name = options[:action]
          result = render(:file => default_template_name(action_name.to_s))
        elsif options[:nothing]
          @view = Babylon::Base::View.new()
        end
      end
      
      ##
      # Actually evaluates the view
      def evaluate
        @view.evaluate if @view
      end
      
      protected
      
      ##
      # Builds the view path.
      def view_path(file_name)
        File.join("app", "views", "#{self.class.name.gsub("Controller","").downcase}", file_name)
      end
      
      ##
      # Default template name used to build stanzas
      def default_template_name(action_name = nil)
        "#{action_name || @action_name}.xml.builder"
      end
      
      ##
      # Creates the view and "evaluates" it to build the XML for the stanza
      def render_for_file(file)
        Babylon.logger.info("RENDERING : #{file}")
        @view = Babylon::Base::View.new(file, assigns)
      end
      
    end
  end
end
