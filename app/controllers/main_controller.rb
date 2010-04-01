class MainController < ApplicationController
  before_filter :set_username

    require "time"
  
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
                        :host => sub[:host],
                        :conversation => status[:conversation],
                        :id => status[:id],
                        :url => status[:url],
                        :author => status[:author],
                        :salmon => status[:salmon]}
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
    finger = Redfinger.finger(params[:remotename])
    profile = finger.profile_page.first.to_s
    user,host = params[:remotename].split("@")
    User.create(:username => user, :host => host, :profile => profile) unless User.find(:first, :conditions => "username='#{user}' AND host='#{host}'")
    Rails.logger.info "called subscribe"
    
    feed_url = finger.updates_from.first.to_s
    Rails.logger.info feed_url.nil?
    render :text => "error".to_json if feed_url.nil?
    xml = HTTParty.get(feed_url)
    hub = FeedTool.is_push?(xml)
    Rails.logger.info "#{xml} #{feed_url} #{hub}"
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    #this_url = doc.xpath("//link[@rel='self']").first['href']
    image = doc.xpath("//link[@rel='avatar']").first['href'] unless doc.xpath("//link[@rel='avatar']").first.nil?
    image ||= "" 
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
                             :image => image,
                             :profile => finger.profile_page.first.to_s } if match.nil?
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
      salmon = doc.xpath("//link[@rel='http://salmon-protocol.org/ns/salmon-replies']").first['href']
      topic = doc.xpath("//link[@rel='self']").first['href']
      updated = doc.xpath("//updated").last.text 
      author = doc.xpath("//author/uri").first.text
      url = doc.xpath("//entry/link[@rel='alternate']").first['href']
      conversation = doc.xpath("//link[@rel='ostatus:conversation']").last['href'] unless doc.xpath("//link[@rel='ostatus:conversation']").last.nil?
      found_user = User.find(:first, :conditions => "username  = '#{user}' AND host = '#{host}'")
      
      res = HTTParty.get(hub, :query => { :"hub.callback" => :"http://redrob.in/main/callback/tylergillies/localhost",
                                  :"hub.mode" => :unsubscribe,
                                  :"hub.topic" => topic,
                                  :"hub.verify" => :sync }) if found_user.nil?
      #render and return :text => "user not found" if found_user.nil?
      found_user.statuses.create(:text => text, :conversation => conversation, :url => url, :author => author, :salmon => salmon)
    end
    Rails.logger.info request.body.string
    render :text => challenge unless challenge.nil?
    render :text => "" if challenge.nil?
  end
  
  def feeds
    user = User.find(:first, :conditions =>  "username = '#{params[:username]}' AND host = 'localhost'" )
    if user.nil?
      render :text => "User does not exist!", :status => 400 and return
    end
    header = <<TEMPLATE
<?xml version="1.0" encoding="UTF-8"?>
<feed xml:lang="en-US" xmlns="http://www.w3.org/2005/Atom" xmlns:thr="http://purl.org/syndication/thread/1.0" xmlns:georss="http://www.georss.org/georss" xmlns:activity="http://activitystrea.ms/spec/1.0/" xmlns:media="http://purl.org/syndication/atommedia" xmlns:poco="http://portablecontacts.net/spec/1.0" xmlns:ostatus="http://ostatus.org/schema/1.0">
 <generator uri="http://redrob.in" version="0.1alpha">Robin</generator>
 <id>http://redrob.in/feeds/#{user.username}</id>
 <title>#{user.username} timeline</title>
 <subtitle>Updates from #{user.username} on Robin!</subtitle>
 <logo>http://avatar.identi.ca/3919-96-20080826101830.png</logo>
 <updated>#{Time.now.xmlschema}</updated>
<author>
 <name>#{user.username}</name>
 <uri>http://redrob.in/users/#{user.username}</uri>

</author>
 <link href="http://pubsubhubbub.appspot.com/" rel="hub"/>
 <link href="http://redrob.in/salmon/#{user.username}" rel="http://salmon-protocol.org/ns/salmon-replies"/>
 <link href="http://redrob.in/salmon/#{user.username}" rel="http://salmon-protocol.org/ns/salmon-mention"/>
 <link href="http://redrob.in/feeds/#{user.username}" rel="self" type="application/atom+xml"/>
<activity:subject>
 <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
 <id>http://redrob.in/users/#{user.username}</id>
 <title>user fullname</title>
 <link ref="alternate" type="text/html" href="http://redrob.in/users/#{user.username}" />
 <link rel="avatar" type="image/jpeg" media:width="178" media:height="178" href="http://avatar.identi.ca/3919-original-20080826101830.jpeg"/>
 <link rel="avatar" type="image/png" media:width="96" media:height="96" href="http://avatar.identi.ca/3919-96-20080826101830.png"/>
 <link rel="avatar" type="image/png" media:width="48" media:height="48" href="http://avatar.identi.ca/3919-48-20080826101830.png"/>
 <link rel="avatar" type="image/png" media:width="24" media:height="24" href="http://avatar.identi.ca/3919-24-20080826101830.png"/>
<poco:preferredUsername>#{user.username}</poco:preferredUsername>
<poco:displayName>user fullname</poco:displayName>
<poco:note>user bio</poco:note>
<poco:address>
 <poco:formatted>97089, US</poco:formatted>
</poco:address>
<poco:urls>
 <poco:type>homepage</poco:type>
 <poco:value>http://redrob.in/users/#{user.username}</poco:value>
 <poco:primary>true</poco:primary>

</poco:urls>
</activity:subject>
TEMPLATE

    entries = []
    
    user.statuses.each do |status|
    replystring = "<link rel='ostatus:attention' href='#{user.profile}' /><link rel='related' href='#{status.reply}' /><thr:in-reply-to ref='#{status.reply}' href='#{status.reply}'></thr:in-reply-to>" if status.reply
       
      entry = <<TEMPLATE
<entry>
 <title>#{status.text}</title>
 <link rel="alternate" type="text/html" href="http://redrob.in/statuses/#{status.id}"/>
 <id>http://redrob.in/statuses/#{status.id}</id>
 <published>#{status.created_at.xmlschema}</published>
 <updated>#{status.updated_at.xmlschema}</updated>
 #{replystring}
 <link rel="ostatus:conversation" href="#{status.conversation}"/>
 <ostatus:forward ref="#{status.conversation}" href="#{status.conversation}"></ostatus:forward>
 <content type="html">#{status.text}</content>

</entry>
TEMPLATE
      entries << entry
    end
    feed = header + entries.join("\n") + "</feed>"
    render :text => feed, :content_type => "application/atom+xml"
  end
  
  def post
    reply = params[:reply]
    Rails.logger.info "REPLY: #{reply}"
    salmon = params[:salmon]
    reply_author = params[:reply_author]
    conversation = params[:conversation]
    author = params[:user]
    user,host = params[:user].split("@") unless params[:user].nil? 
    person = User.find(:first, :conditions => "username = '#{user}' AND host = '#{host}'")
    username = @user.username
    text = params[:text]
    title = params[:text]
    text[/@\w+/] = "&lt;a href='#{person.profile}'&gt;@#{user}&lt;/a&gt;" unless params[:user].nil?
    conversation ||= "http://redrob.in/conversations/#{Conversation.create.object_id}" 
    status = @user.statuses.create(:title => title, :text => text, :conversation => conversation, :reply => reply, :reply_author => reply_author)
    hub = "http://pubsubhubbub.appspot.com/"
    #salmon = status.salmon
    #author = status.author unless reply.nil?
    HTTParty.post(hub, :body => { :"hub.mode" => :publish, :"hub.url" => "http://redrob.in/feeds/#{@user.username}" })
    HTTParty.get("http://redrob.in/salmon/send_salmon", :query => { :title => title, :text => text, :status_id => status.id, :username => username, :salmon => salmon, :author => author }) unless reply.nil?

    render :text => "Ok".to_json
  end    
  
  def webfinger
    uri = params[:uri]
    username = uri.gsub(/(?:acct:)?([^@]+)@redrob\.in/){ $1 }

    output = <<-EOF
<?xml version='1.0' encoding='UTF-8'?>
<XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'>
 
    <Subject>acct:#{username}@redrob.in</Subject>
    <Alias>http://redrob.in/users/#{username}</Alias>
 
    <Link rel='magic-public-key'
          href='data:application/magic-public-key;RSA.xA_Fc4BlK439U1Ow5vUyY5A-Zcdpaniyt7v45jnd5S6-dIUWdHtGSN5sYF6hNb8OyMyVJVqAkBtzG0jGNL4HJQ==.AQAB' />
    <Link rel='http://webfinger.net/rel/profile-page'
          type='text/html'
          href='http://redrob.in/users/#{username}' />
    <Link rel='http://salmon-protocol.org/ns/salmon-mention'
          href='http://redrob.in/push/callback' />
    <Link rel='http://schemas.google.com/g/2010#updates-from'
          type='application/atom+xml'
          href='http://redrob.in/feeds/#{username}' />
</XRD>
    EOF
    render :text => output, :content_type => "application/xrd+xml"
  end
  
  def users
    username = params[:username]
    user = User.find(:first, :conditions => "username = '#{username}' AND host = 'localhost'")
    if user.nil?
      render :text => "no such user", :status => 400 and return
    end
        
    statuses = user.statuses.map(&:title).reverse.join("<p>")
    render :text => statuses
  end
  
  def statuses
    status_number = params[:status_number]
    message = Status.find(status_number)
    render :text => message.title
  end
    
    
    
end
