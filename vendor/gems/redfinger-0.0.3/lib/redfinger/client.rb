require 'restclient'
require 'nokogiri'
require 'uri'

module Redfinger
  class Client
    attr_accessor :account, :domain, :uri_template

    def initialize(email, uri_template = nil)
      self.account = urify(email)
      self.domain = account.split('@').last
    end

    def finger
      self.uri_template ||= retrieve_template_from_xrd
      Finger.new RestClient.get(swizzle).body
    end

    def xrd_url(ssl = true)
      "http#{'s' if ssl}://#{domain}/.well-known/host-meta"
    end

    private

    def swizzle
      uri_template.gsub '{uri}', URI.escape(self.account)
    end

    def retrieve_template_from_xrd(ssl = true)
      doc = Nokogiri::XML::Document.parse(RestClient.get(xrd_url(ssl)).body)
      if doc.namespaces["xmlns:hm"] != "http://host-meta.net/xrd/1.0"
        # it's probably not finger, let's try without ssl
        # http://code.google.com/p/webfinger/wiki/WebFingerProtocol
        # says first ssl should be tried then without ssl, should fix issue #2
        doc = Nokogiri::XML::Document.parse(RestClient.get(xrd_url(false)).body)
      end
      unless doc.at_xpath('.//hm:Host').content == self.domain
        raise Redfinger::SecurityException, "The XRD document's host did not match the account's host."
      end

      doc.at('Link[rel=lrdd]').attribute('template').value
    rescue Errno::ECONNREFUSED, RestClient::ResourceNotFound
      if ssl
        retrieve_template_from_xrd(false)
      else
        raise Redfinger::ResourceNotFound, "Unable to find the host XRD file."
      end
    end

    def urify(email)
      email = "acct:#{email}" unless email.include?("acct:")
      email
    end
  end
end
