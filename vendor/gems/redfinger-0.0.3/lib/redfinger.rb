require 'redfinger/link_helpers'
require 'redfinger/link'
require 'redfinger/finger'
require 'redfinger/client'

module Redfinger
  class ResourceNotFound < StandardError; end
  # A SecurityException occurs when something in the
  # webfinger process does not appear safe, such as
  # mismatched domains or an unverified XRD signature.
  class SecurityException < StandardError; end

  # Finger the provided e-mail address.
  def self.finger(email)
    Redfinger::Client.new(email).finger
  end
end
