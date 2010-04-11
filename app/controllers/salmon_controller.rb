class SalmonController < ApplicationController
  require 'time'
  require 'base64'
  require 'openssl'
  require 'net/http'
  require 'uri'
  require 'cgi'
  
  protect_from_forgery :only => [:create, :update, :destroy]
  
  def create_env
    
  end
  
  def check_author
    
  end

  def user
    username = params[:username]
    user = User.find(:first, :conditions => "username = '#{username}' and host='localhost'")
    if user.nil?
      render :text => "No user by that name", :status => 400
      return
    end
    body = request.body.read
    #Rails.logger.info body
    doc = Nokogiri::XML(body)
    doc.remove_namespaces!
    sig = doc.xpath("//sig").first.text
    message = doc.xpath("//data").first.text
    message = message.tr('-_','+/').unpack('mU*')[0]
    Rails.logger.info message
    message = Nokogiri::XML(message)
    message.remove_namespaces!

    author = message.xpath("//author/name").first.text
    key_name = message.xpath("//author/uri").first.text
    content = message.xpath("//content").first.text
    domain = key_name.gsub(/^(?:[^\/]+:\/\/)?([^\/:]+)/,"\1")
    domain = "#{$1}"
    Rails.logger.info author,domain
    junk,mod,ex = Redfinger.finger("#{author}@#{domain}").magic_key.first.to_s.split(".")
    key = OpenSSL::PKey::RSA.new
    mod =  mod.tr('-_','+/').unpack('mU*')[0]
    ex =   ex.tr('-_','+/').unpack('mU*')[0]
    mod = OpenSSL::BN.new mod.to_s.unpack("H*").to_s
    ex =   OpenSSL::BN.new ex.to_s.unpack("H*").to_s

    sig = sig.tr('-_','+/').unpack('mU*')[0]

    key.n = mod
    key.e =ex
    Rails.logger.info "verfied?",key.verify( OpenSSL::Digest::SHA256.new, sig, message )
    render :text => "Ok"
    Status.create(:to => username, :title => content, :author => author)
    
  end
  
  def send_salmon
    salmon = params[:salmon]
    title = params[:title]
    status_id = params[:status_id]
    username = params[:username]
    author = params[:author]
    finger = Redfinger.finger(author)
    author = finger.profile_page.first.to_s
    endpoint = salmon
    entry = <<SAMPLE
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:service="http://activitystrea.ms/service-provider" xmlns:activity="http://activitystrea.ms/spec/1.0/">
  <activity:verb>http://activitystrea.ms/schema/1.0/post</activity:verb>
  <title type="text">#{title}</title>
  <service:provider>
    <name>Robin</name>
    <uri>http://redrob.in/</uri>
    <icon>https://cliqset-applications.s3.amazonaws.com/605fcb40fef7c5b1ba5fed445ebda34d_icon</icon>
  </service:provider>
  <activity:object>
    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>
    <content type="text">#{title}</content>
    <link rel="alternate" type="text/html" href="http://redrob.in/statuses/#{status_id}" />
    <id>http://redrob.in/statuses/#{status_id}</id>
  </activity:object>
  <category scheme="http://schemas.cliqset.com/activity/categories/1.0" term="StatusPosted" label="Status Posted" />
  <updated>#{Time.now.xmlschema}</updated>
  <published>#{Time.now.xmlschema}</published>
  <id>note</id>
  <link href="http://cliqset.com/users/#{username}" type="text/xhtml" rel="alternate" title="#{username} posted a note on redrob.in" />
  <author>
    <name>#{username}</name>
    <uri>acct:#{username}@redrob.in</uri>
  </author>
  <activity:actor xmlns:poco="http://portablecontacts.net/spec/1.0">
    <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
    <poco:name>
      <poco:givenName>Tyler</poco:givenName>
      <poco:familyName>Gillies</poco:familyName>
    </poco:name>
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://avatar.identi.ca/3919-original-20080826101830.jpeg" media:height="80" media:width="80" />
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://avatar.identi.ca/3919-original-20080826101830.jpeg" media:height="120" media:width="120" />
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://avatar.identi.ca/3919-original-20080826101830.jpeg" media:height="200" media:width="200" />
    <link href="http://redrob.in/users/#{username}" rel="alternate" type="text/html" length="0" />
    <id>http://redrob.in/users/#{username}</id>
  </activity:actor>
  <link href="#{author}" rel="ostatus:attention" />
</entry>
SAMPLE

    privkey = OpenSSL::PKey::RSA.new(File.read("privkey"))
    data = [entry].pack('mU*').tr('+/','-_').gsub("\n",'')
    sig = privkey.sign(OpenSSL::Digest::SHA256.new, data)
    sig = [sig].pack('mU*').tr('+/','-_').gsub("\n",'')
    
    post_body = <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<me:env xmlns:me='http://salmon-protocol.org/ns/magic-env'>
  <me:data type='application/atom+xml'>
#{data}
  </me:data>
  <me:encoding>base64url</me:encoding>
  <me:alg>RSA-SHA256</me:alg>
  <me:sig>
#{sig}
  </me:sig>
</me:env>
EOF

  sig = sig.tr('-_','+/').unpack('mU*')[0]
  #data = data.tr('-_','+/').unpack('m')[0]

   public_key=privkey.public_key
   mod = public_key.n.to_s(2)
   ex = public_key.e.to_s(2)
   Rails.logger.info "modulus: #{public_key.n.to_s(2)} #{mod}"
   
   mod = [mod].pack('mU*').tr('+/','-_').gsub("\n",'')
   ex = [ex].pack('mU*').tr('+/','-_').gsub("\n",'')
   Rails.logger.info "RSA.#{mod}.#{ex}"
   if public_key.verify( OpenSSL::Digest::SHA256.new, sig, data )
    Rails.logger.info "Verified!" 
  else

    Rails.logger.info "FAIL!"
  end
  #url = URI.parse(endpoint)
   res = HTTParty.post(params[:salmon], :body => post_body, :headers => { 'content-type' => "application/magic-envelope+xml" })
    Rails.logger.info "REPLY: #{res}"
    render :text => "look at log"

  end
  

end
