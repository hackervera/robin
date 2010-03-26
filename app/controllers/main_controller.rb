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
     @statuses = []
     @user.subscriptions.each do |sub|
       user = User.find(:first, :conditions => "username = '#{sub[:user]}' AND host = '#{sub[:host]}'")
       user.statuses.each do |status|
         @statuses << { :text => status[:text],
                        :updated => status[:updated_at],
                        :user => sub[:user],
                        :image => sub[:image],
                        :host => sub[:host]}
         end
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
    user,host = params[:remotename].split("@")
    User.create(:username => user, :host => host) unless User.find(:first, :conditions => "username='#{user}' AND host='#{host}'")
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
    res = HTTParty.get(hub, :query => { :"hub.callback" => :"http://redrob.in/main/callback/#{user}/#{host}",
                                  :"hub.mode" => :subscribe,
                                  :"hub.topic" => feed_url,
                                  :"hub.verify" => :sync })
    Rails.logger.info res
    @user.subscriptions = [] if @user.subscriptions.nil?
    match = nil
    user,host = params[:remotename].split("@")
    @user.subscriptions.each do |sub|
      match = 1 if sub[:user] == user && sub[:host] == host
    end
        
    @user.subscriptions << { :hub => hub, 
                             :topic => feed_url, 
                             :user => user,
                             :host => host, 
                             :image => image } if match.nil?
    @user.save
    render :text => "#{hub} #{feed_url} #{image}".to_json
  end  
    
  def callback
    challenge = params[:"hub.challenge"]
    user = params[:user]
    host = params[:host]
    xml = request.body.string
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    Rails.logger.info xml
    unless xml.empty?
      text = doc.xpath("//content").last.text
      hub = doc.xpath("//link[@rel='hub']").first['href']
      topic = doc.xpath("//link[@rel='self']").first['href']
      found_user = User.find(:first, :conditions => "username  = '#{user}' AND host = '#{host}'")
      render :text => "user not found" if found_user.nil?
      found_user.statuses.create(:text => text)
    end
    Rails.logger.info request.body.string
    render :text => challenge unless challenge.nil?
    render :text => "" if challenge.nil?
  end
            
end
