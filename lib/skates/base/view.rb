module Skates
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
      # You can also use :locals => {:name => value} to use defined locals in your embedded views.
      def render(xml, options = {})
        # First, we need to identify the partial file path, based on the @view_template path.
        partial_path = (@view_template.split("/")[0..-2] + options[:partial].split("/")).join("/").gsub(".xml.builder", "") + ".xml.builder"
        raise ViewFileNotFound, "No such file #{partial_path}" unless Skates.views[partial_path] 
        saved_locals = @locals
        @locals = options[:locals]
        eval(Skates.views[partial_path], binding, partial_path, 1)
        @locals = saved_locals # Re-assign the previous locals to be 'clean'
      end
      
      ##
      # Instantiate a new view with the various varibales passed in assigns and the path of the template to render.
      def initialize(path = "", assigns = {}) 
        @view_template = path 
        @locals = {}
        assigns.each do |key, value| 
          instance_variable_set(:"@#{key}", value) 
        end 
      end 
      
      ## 
      # "Loads" the view file, and uses the Nokogiri Builder to build the XML stanzas that will be sent. 
      def evaluate 
        return if @view_template == ""
        raise ViewFileNotFound, "No such file #{@view_template}" unless Skates.views[@view_template] 
        builder = Nokogiri::XML::Builder.new 
        builder.stream do |xml|
          eval(Skates.views[@view_template], binding, @view_template, 1)
        end
        builder.doc.root.children # we output the document built 
      end 
      
      ##
      # Used to macth locals variables
      def method_missing(sym, *args, &block)
        raise NameError, "undefined local variable or method `#{sym}' for #{self}" unless @locals[sym]
        @locals[sym]
      end
      
    end 
  end 
end
