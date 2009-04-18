module Babylon
  module Base
    
    class ViewFileNotFound < Errno::ENOENT; end
    
    ##
    # Your application's views (stanzas) should be descendant of this class.
    class View 
      attr_reader :output, :view_template
      
      ##
      # Instantiate a new view with the various varibales passed in assigns and the path of the template to render.
      def initialize(path, assigns)
        @output = nil
        @view_template = path
        assigns.each do |key, value| 
          instance_variable_set("@#{key}", value)
          self.class.send(:define_method, key) do # Defining accessors
            value
          end
        end
      end
      
      ##
      # "Loads" the view file, and uses the Nokogiri Builder to build the XML stanzas that will be sent.
      def evaluate
        raise ViewFileNotFound unless Babylon.views[@view_template]
        xml = Nokogiri::XML::Builder.new
        eval(Babylon.views[@view_template])
        @output = xml.doc # we output the document built
      end 
    end 
  end 
end
