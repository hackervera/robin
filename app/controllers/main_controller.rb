class MainController < ApplicationController
  def main
  end
  def findname
    user = params[:user]
    users = []
    found_users = User.find_all_by_username(user)
    if found_users.empty?
      render :text => "none".to_json
    end
    found_users.each do |user|
      users << "#{user.username}@#{user.host}"
    end
    render :text => users.to_json
  end  
  def subscribe
    finger = Redfinger.finger(params[:remotename])
    feed_url = finger.updates_from.first.to_s
    
    render :text => "error".to_json if feed_url.nil?
    xml = HTTParty.get(feed_url)
    hub = FeedTool.is_push?(xml)
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    image = doc.xpath("//link[@rel='avatar']").first['href']
    res = HTTParty.get(hub, :query => { :"hub.callback" => :"http://redrob.in/main/callback",
                                  :"hub.mode" => :subscribe,
                                  :"hub.topic" => feed_url,
                                  :"hub.verify" => :sync })
    Rails.logger.info res
    render :text => "#{hub} #{feed_url} #{image}".to_json
  end  
    
  def callback
    challenge = params[:"hub.challenge"]
    Rails.logger.info request.body.string
    render :text => challenge unless challenge.nil?
  end
            
end
