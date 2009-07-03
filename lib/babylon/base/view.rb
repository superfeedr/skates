module Babylon
  module Base
    
    class ViewFileNotFound < Errno::ENOENT; end
    
    ##
    # Your application's views (stanzas) should be descendant of this class.
    class View 
      attr_reader :view_template 
      
      ##
      # Used to 'include' another view inside an existing view. 
      # The caller needs to pass the context in which the partial will be rendered
      # Render must be called with :partial as well (other options will be supported later). The partial vale should be a relative path
      # to another file view, from the calling view.
      def render(xml, options = {})
        # First, we need to identify the partial file path, based on the @view_template path.
        partial_path = (@view_template.split("/")[0..-2] + options[:partial].split("/")).join("/").gsub(".xml.builder", "") + ".xml.builder"
        raise ViewFileNotFound, "No such file #{partial_path}" unless Babylon.views[partial_path] 
        eval(Babylon.views[partial_path], binding, partial_path, 1)
      end
      
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
        raise ViewFileNotFound, "No such file #{@view_template}" unless Babylon.views[@view_template] 
        builder = Nokogiri::XML::Builder.new 
        builder.stream do |xml|
          eval(Babylon.views[@view_template], binding, @view_template, 1)
        end
        builder.doc.root.children # we output the document built 
      end 
    end 
  end 
end
