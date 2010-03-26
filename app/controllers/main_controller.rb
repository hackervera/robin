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
  
  def post
    require "Time"
    hub = ""
    template = <<TEMPLATE
<?xml version="1.0" encoding="UTF-8"?>
<feed xml:lang="en-US" xmlns="http://www.w3.org/2005/Atom" xmlns:thr="http://purl.org/syndication/thread/1.0" xmlns:georss="http://www.georss.org/georss" xmlns:activity="http://activitystrea.ms/spec/1.0/" xmlns:media="http://purl.org/syndication/atommedia" xmlns:poco="http://portablecontacts.net/spec/1.0" xmlns:ostatus="http://ostatus.org/schema/1.0">
 <generator uri="http://redrob.in" version="0.1alpha">Robin</generator>
 <id>http://redrob.in/feeds/#{@user.username}</id>
 <title>#{@user.username} timeline</title>
 <subtitle>Updates from #{@user.username} on Robin!</subtitle>
 <logo>http://avatar.identi.ca/3919-96-20080826101830.png</logo>
 <updated>#{Time.now.xmlschema}</updated>
<author>
 <name>#{@user.username}</name>
 <uri>http://redrob.in/users/#{@user.username}</uri>

</author>
 <link href="http://identi.ca/main/push/hub" rel="hub"/>
 <link href="http://redrob.in/salmon/#{@user.username}" rel="http://salmon-protocol.org/ns/salmon-replies"/>
 <link href="http://redrob.in/salmon/#{@user.username}" rel="http://salmon-protocol.org/ns/salmon-mention"/>
 <link href="http://redrob.in/feeds/#{@user.username}" rel="self" type="application/atom+xml"/>
<activity:subject>
 <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
 <id>http://redrob.in/users/#{@user.username}</id>
 <title>#{@user.fullname}</title>
 <link rel="avatar" type="image/png" media:width="48" media:height="48" href="http://avatar.identi.ca/3919-48-20080826101830.png"/>

<poco:preferredUsername>#{@user.username}</poco:preferredUsername>
<poco:displayName>#{@user.fullname}</poco:displayName>
<poco:note>#{@user.bio}</poco:note>
<poco:address>
 <poco:formatted>97089, US</poco:formatted>
</poco:address>
<poco:urls>
 <poco:type>homepage</poco:type>
 <poco:value>#{@user.homepage}</poco:value>
 <poco:primary>true</poco:primary>

</poco:urls>
</activity:subject>
<entry>
 <title>RT @reality &quot;ACS: Law&quot; sounds like a TV show !ppuk</title>
 <link rel="alternate" type="text/html" href="http://identi.ca/notice/26153733"/>
 <id>http://identi.ca/notice/26153733</id>
 <published>2010-03-26T03:59:13-07:00</published>
 <updated>2010-03-26T03:59:13-07:00</updated>
 <link rel="ostatus:conversation" href="http://identi.ca/conversation/26143063"/>
 <ostatus:forward ref="http://identi.ca/notice/26150729" href="http://identi.ca/notice/26150729"></ostatus:forward>
 <content type="html">RT @&lt;span class=&quot;vcard&quot;&gt;&lt;a href=&quot;http://identi.ca/user/55937&quot; class=&quot;url&quot; title=&quot;Luke Slater&quot;&gt;&lt;span class=&quot;fn nickname&quot;&gt;reality&lt;/span&gt;&lt;/a&gt;&lt;/span&gt; &amp;quot;ACS: Law&amp;quot; sounds like a TV show !ppuk</content>

</entry>
TEMPLATE

  end
            
end
