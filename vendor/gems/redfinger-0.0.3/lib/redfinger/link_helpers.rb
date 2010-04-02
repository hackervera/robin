require 'nokogiri'

module Redfinger
  module LinkHelpers
    # An array of links with hCard information about this e-mail address.
    def hcard
      relmap('http://microformats.org/profile/hcard')
    end
    
    # An array of links of OpenID providers for this e-mail address.
    def open_id
      relmap('http://specs.openid.net/auth/', true)
    end
    
    # An array of links to profile pages belonging to this e-mail address.
    def profile_page
      relmap('http://webfinger.net/rel/profile-page')
    end
    
    # An array of links to XFN compatible URLs for this e-mail address.
    def xfn
      relmap('http://gmpg.org/xfn/', true)
    end
    
    def ostatus
      relmap('http://ostatus.org/schema/1.0/subscribe', true)
    end
    
    def updates_from
      relmap('http://schemas.google.com/g/2010#updates-from', true)
    end

    def salmon
      relmap('http://salmon-protocol.org/ns/salmon-replies', true)
    end
        
    
    protected
    
    def relmap(uri, substring=false)
      @doc.css("Link[rel#{'^' if substring}=\"#{uri}\"]").map{|e| Link.new(e)}
    end
  end
end
