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
        @rendered = false
      end
      
      ##
      # Performs the action and calls back the optional block argument : you should not override this function
      def perform(action, &block)
        @action_name = action
        @block = block
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
           if !["@rendered", "@action_name", "@block"].include? var
             vars[var[1..-1]] = instance_variable_get(var)
           end
        end
        return vars
      end
      
      ##
      # Called by default after each action to "build" a XMPP stanza. By default, it will use the /controller_name/action.xml.builder
      # You can use the following options :
      #   - :file : render a specific file (can be in a different controller)
      #   - :action : render another action of the current controller
      #   - :nothing : doesn't render anything
      def render(options = nil) 
        return if @rendered # Avoid double rendering
        
        if options.nil? # default rendering
          render(:file => default_template_name)
        elsif options[:file]
          file = options[:file]
          if file =~ /^\// # Render from view root
            render_for_file(File.join("app", "views", "#{file}.xml.builder"))
          else
            render_for_file(view_path(file)) 
          end
        elsif action_name = options[:action]
          render(:file => default_template_name(action_name.to_s))
        elsif options[:nothing]
          # Then we don't do anything.
        end
        # And finally, we set up rendered to be true 
        @rendered = true
      end
      
      def response
        @view.output
      end
      
      protected
      
      def view_path(file_name)
        File.join("app", "views", "#{self.class.name.gsub("Controller","").downcase}", file_name)
      end
      
      # Default template name used to build stanzas
      def default_template_name(action_name = nil)
        "#{action_name || @action_name}.xml.builder"
      end
      
      # Creates the view and "evaluates" it to build the XML for the stanza
      def render_for_file(file)
        Babylon.logger.info("RENDERING : #{file}")
        @view = Babylon::Base::View.new(file, assigns)
        @view.evaluate
      end
    end
  end
end
