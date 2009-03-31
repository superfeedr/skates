class <%= controller_class_name %> < Babylon::Base::Controller  
  <% controller_actions.each do |action, prio, xpath| %>
    def <%= action %>
      # This will be called when a stanza matches <%= xpath %>
    end
  <% end %>
end