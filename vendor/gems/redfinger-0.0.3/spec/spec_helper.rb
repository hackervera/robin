$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'redfinger'
require 'spec'
require 'spec/autorun'
require 'webmock/rspec'

include WebMock

def host_xrd
  <<-XML
  <?xml version='1.0' encoding='UTF-8'?>
  <!-- NOTE: this host-meta end-point is a pre-alpha work in progress.   Don't rely on it. -->
  <!-- Please follow the list at http://groups.google.com/group/webfinger -->
  <XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0' 
       xmlns:hm='http://host-meta.net/xrd/1.0'>
    <hm:Host xmlns='http://host-meta.net/xrd/1.0'>example.com</hm:Host>
    <Link rel='lrdd' 
          template='http://example.com/webfinger/?q={uri}'>
      <Title>Resource Descriptor</Title>
    </Link>
  </XRD>
  XML
end

def finger_xrd
  <<-XML
  <?xml version='1.0'?>
  <XRD xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'>
  	<Subject>acct:abc@example.com</Subject>
  	<Alias>http://www.google.com/profiles/abc</Alias>
  	<Link rel='http://portablecontacts.net/spec/1.0' href='http://www-opensocial.googleusercontent.com/api/people/'/>
  	<Link rel='http://webfinger.net/rel/profile-page' href='http://www.google.com/profiles/abc' type='text/html'/>
  	<Link rel='http://microformats.org/profile/hcard' href='http://www.google.com/profiles/abc' type='text/html'/>
  	<Link rel='http://gmpg.org/xfn/11' href='http://www.google.com/profiles/abc' type='text/html'/>
  	<Link rel='http://specs.openid.net/auth/2.0/provider' href='http://www.google.com/profiles/abc'/>
  	<Link rel='describedby' href='http://www.google.com/profiles/abc' type='text/html'/>
  	<Link rel='describedby' href='http://s2.googleusercontent.com/webfinger/?q=acct%3Aabc%example.com&amp;fmt=foaf' type='application/rdf+xml'/>
  	<Link rel='http://schemas.google.com/g/2010#updates-from' href='http://buzz.googleapis.com/feeds/100660544095714416357/public/posted' type='application/atom+xml'/>
  </XRD>
  XML
end

def stub_success
  stub_request(:get, 'https://example.com/.well-known/host-meta').to_return(:status => 200, :body => host_xrd)
  stub_request(:get, /webfinger\/\?q=.*/).to_return(:status => 200, :body => finger_xrd)
end

Spec::Runner.configure do |config|
  
end
