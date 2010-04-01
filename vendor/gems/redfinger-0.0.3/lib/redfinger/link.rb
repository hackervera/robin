require 'nokogiri'
require 'hashie'

module Redfinger
  class Link < Hashie::Mash
    def initialize(xml_link)
      self[:rel] = xml_link['rel']
      self[:href] = xml_link['href']
      self[:type] = xml_link['type']
      self[:template] = xml_link['template']
    end
    
    # Outputs the URL of the link, useful for using 
    # a Link directly in other libraries.
    def to_s
      self.href
    end
    def to_temp
      self.template
    end
  end
end
