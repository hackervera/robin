require 'nokogiri'

module Redfinger
  # The result of a Webfinger. For more information about
  # special helpers that are availale to pull specific types
  # of URLs, see Redfinger::LinkHelpers
  class Finger
    def initialize(xml) # :nodoc:
      @doc = Nokogiri::XML::Document.parse(xml)
      @subject = @doc.at_css('Subject').content
    end
    
    # All of the links provided by the Webfinger response.
    def links
      @links ||= @doc.css('Link').map{|l| Link.new(l)}
    end
    
    def inspect # :nodoc:
      "<#Redfinger::Finger subject=\"#{@subject}\">"
    end
    
    include Redfinger::LinkHelpers
  end
end