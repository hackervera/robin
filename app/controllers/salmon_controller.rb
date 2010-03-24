class SalmonController < ApplicationController
  require 'time'
  
  def create_env
    
  end
  
  def check_author
    
  end
  
  def send_salmon
    notice = "http://opengard.in/notice/2695"
    #endpoint = "http://dev.walkah.me/main/salmon/user/1"
    endpoint = "http://opengard.in/main/salmon/user/1"
    #endpoint = "http://identi.ca/main/salmon/user/141089"
    entry = <<SAMPLE
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:service="http://activitystrea.ms/service-provider" xmlns:activity="http://activitystrea.ms/spec/1.0/">
  <activity:verb>http://activitystrea.ms/schema/1.0/post</activity:verb>
  <title type="text">#{Time.now}</title>
  <service:provider>
    <name>Cliqset</name>
    <uri>http://cliqset.com/</uri>
    <icon>https://cliqset-applications.s3.amazonaws.com/605fcb40fef7c5b1ba5fed445ebda34d_icon</icon>
  </service:provider>
  <activity:object>
    <activity:object-type>http://activitystrea.ms/schema/1.0/note</activity:object-type>
    <content type="text">this is a test. woot. Time now: #{Time.now}</content>
    <link rel="alternate" type="text/html" href="http://cliqset.com/user/charlie/yfLi3ZfLcEQHRQee" />
    <id>#{Time.now}</id>
  </activity:object>
  <category scheme="http://schemas.cliqset.com/activity/categories/1.0" term="StatusPosted" label="Status Posted" />
  <updated>#{Time.now.xmlschema}</updated>
  <published>#{Time.now.xmlschema}</published>
  <id>note</id>
  <link href="http://cliqset.com/user/charlie/yfLi3ZfLcEQHRQee" type="text/xhtml" rel="alternate" title="charlie posted a note on Cliqset" />
  <author>
    <name>charlie</name>
    <uri>acct:tjgillies@test.opengard.in</uri>
  </author>
  <activity:actor xmlns:poco="http://portablecontacts.net/spec/1.0">
    <activity:object-type>http://activitystrea.ms/schema/1.0/person</activity:object-type>
    <poco:name>
      <poco:givenName>Charlie</poco:givenName>
      <poco:familyName>Cauthen</poco:familyName>
    </poco:name>
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://dynamic.cliqset.com/avatar/charlie?s=80" media:height="80" media:width="80" />
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://dynamic.cliqset.com/avatar/charlie?s=120" media:height="120" media:width="120" />
    <link xmlns:media="http://purl.org/syndication/atommedia" type="image/png" rel="avatar" href="http://dynamic.cliqset.com/avatar/charlie?s=200" media:height="200" media:width="200" />
    <link href="http://cliqset.com/user/charlie" rel="alternate" type="text/html" length="0" />
    <id>http://opengard.in/tjgillies</id>
  </activity:actor>
  <link href="http://opengard.in/tjgillies" rel="ostatus:attention" />
</entry>
SAMPLE

    require 'base64'
    require 'openssl'
    require 'net/http'
    require 'uri'
    require 'cgi'
    privkey = OpenSSL::PKey::RSA.new(File.read("/home/tyler/privkey"))
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
