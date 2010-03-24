

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end

module FeedTool
  def FeedTool.is_push?(xml)
    #Rails.logger.info xml.slice(0,500)
    doc = Nokogiri::XML(xml)
    Rails.logger.info "Class: #{doc.class}\n\n"
    doc.remove_namespaces!
    links = doc.xpath("//link")
    Rails.logger.info "LINKS: #{links.inspect}\n\n"
    links.each do |node|
      #Rails.logger.info "NODE_VARS: #{node.class} #{node.href}"
      @hub = node.attributes['href'].to_s if node.attributes['rel'].to_s == "hub" 
      Rails.logger.info "Node attrs: #{node.attributes}\n\n"
    end
    @hub ||= false
    Rails.logger.info "HUB: #{@hub}\n\n"
    @hub
  end
 end