require File.dirname(__FILE__) + '/../../../spec_helper'

describe Babylon::Base::Stanza do
end

describe Babylon::Base::Message do
  it "should parse" do
    stanza = Babylon::Base::Message.new
    stanza.parse("<message from='northumberland@shakespeare.lit/westminster' id='stanza_id_1234' to='kingrichard@royalty.england.lit/throne' type='get'><body>My lord, dispatch; read o'er these articles.</body></message>")  
    stanza.body.should == "My lord, dispatch; read o'er these articles."
    stanza.to.should == "kingrichard@royalty.england.lit/throne"
    stanza.from.should == "northumberland@shakespeare.lit/westminster"
    stanza.stanza_id.should == "stanza_id_1234"
    stanza.lang.should be_nil
    stanza.stanza_type.should == "get"
  end
end

describe Babylon::Base::Iq do
end

describe Babylon::Base::Presence do
end