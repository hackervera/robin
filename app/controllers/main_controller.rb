class MainController < ApplicationController
  before_filter :set_username
  
  def set_username
    
    @user = User.find_by_username("tylergillies")
    @user ||= User.create(:username => "tylergillies", :host => "localhost")
  end
    
  def main
    @subs = []
    @user.subscriptions = [] if @user.subscriptions.nil?
   @user.subscriptions.each do |sub|
     @subs << "<img src=#{sub[:image]} width=48 height=48>"
   end
      
    
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
    user_split = params[:remotename].split("@")
    User.create(:username => user_split.first, :host => user_split.second) unless User.find(:first, :conditions => "username='#{user_split.first}' AND host='#{user_split.second}'")
    Rails.logger.info "called subscribe"
    finger = Redfinger.finger(params[:remotename])
    feed_url = finger.updates_from.first.to_s
    Rails.logger.info feed_url.nil?
    render :text => "error".to_json if feed_url.nil?
    xml = HTTParty.get(feed_url)
    Rails.logger.info xml
    hub = FeedTool.is_push?(xml)
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    image = doc.xpath("//link[@rel='avatar']").first['href']
    res = HTTParty.get(hub, :query => { :"hub.callback" => :"http://redrob.in/main/callback",
                                  :"hub.mode" => :subscribe,
                                  :"hub.topic" => feed_url,
                                  :"hub.verify" => :sync })
    Rails.logger.info res
    @user.subscriptions = [] if @user.subscriptions.nil?
    match = nil
    @user.subscriptions.each do |sub|
      match = 1 if sub[:user] == params[:remotename]
    end
        
    @user.subscriptions << { :hub => hub, :topic => feed_url, :user => params[:remotename], :image => image } if match.nil?
    @user.save
    render :text => "#{hub} #{feed_url} #{image}".to_json
  end  
    
  def callback
    challenge = params[:"hub.challenge"]
    Rails.logger.info request.body.string
    render :text => challenge unless challenge.nil?
  end
            
end
