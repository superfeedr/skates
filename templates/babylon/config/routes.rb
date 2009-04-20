# Routes require an xpath against which to match, and a controller/action pair to which to map.
#
# xpath("//message[@type = 'chat']").to(:controller => "message", :action => "receive")
#
# Routes can be assigned priorities. The highest priority executes first, and the default priority is 0.
#
# xpath("//message[@type = 'chat']").to(:controller => "message", :action => "priority").priority(5000000)
#
# A number of namespaces have been specified for you; see Babylon::StanzaRouter::DEFAULT_NAMESPACES.
#
# xpath("//iq[@type='get']/disco_info:query").to(:controller => "discovery", :action => "services")
#
# There are a few helper methods for generating xpaths. The following is equivalent to the above example:
#
# disco_info.to(:controller => "discovery", :action => "services")
#
# If you want to add custom namespaces, simply do:
# 
# namespace "custom", "http://me.org/namespaces/custom"
# and you can then match xpath("//custom:node")
#
# See lib/babylon/router/dsl.rb for more helpers.
Babylon.router.draw do
  
end
