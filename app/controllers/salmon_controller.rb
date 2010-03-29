class SalmonController < ApplicationController
  require 'time'
  
  def create_env
    
  end
  
  def check_author
    
  end
  
  def send_salmon
    salmon = params[:salmon]
    title = params[:title]
    status_id = params[:status_id]
    username = params[:username]
    notice = "http://opengard.in/notice/2695"
    #endpoint = "http://dev.walkah.me/main/salmon/user/1"
    endpoint = salmon
    #endpoint = "http://identi.ca/main/salmon/user/141089"
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
    <content type="text">#{text}</content>
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
    <id>http://redrob.in/#{username}</id>
  </activity:actor>
  <link href="#{reply_author}" rel="ostatus:attention" />
</entry>
SAMPLE

    require 'base64'
    require 'openssl'
    require 'net/http'
    require 'uri'
    require 'cgi'
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
  url = URI.parse(endpoint)
   req = Net::HTTP::Post.new(url.path)
   req.body = post_body
   req.content_type = "application/magic-envelope+xml"
   #header_stuff = req.each_header {|k,v| puts k,v}
   Rails.logger.warn "req: #{post_body}"
   res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
   Rails.logger.warn "res: #{res.body} #{res.code}"
   render :text => "look at log"

  end
  

end
