module Babylon
  module Base
    
    class ViewFileNotFound < Errno::ENOENT; end
    
    ##
    # Your application's views (stanzas) should be descendant of this class.
    class View 
      attr_reader :view_template 
      
      ##
      # Instantiate a new view with the various varibales passed in assigns and the path of the template to render.
      def initialize(path = "", assigns = {}) 
        @view_template = path 
        
        assigns.each do |key, value| 
          instance_variable_set(:"@#{key}", value) 
        end 
      end 
      
      ## 
      # "Loads" the view file, and uses the Nokogiri Builder to build the XML stanzas that will be sent. 
      def evaluate 
        return if @view_template == ""
        raise ViewFileNotFound unless Babylon.views[@view_template] 
        xml = Nokogiri::XML::Builder.new 
        eval(Babylon.views[@view_template]) 
        xml.doc # we output the document built 
      end 
    end 
  end 
end
