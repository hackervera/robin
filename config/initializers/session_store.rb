# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rstatus_session',
  :secret      => '71bfba384176462676a7892d26eb13a6a5c179b49537e8baf0f3c648fa3f560b3080f3bc6e328fe0eed63123a4cb87dac47e4c36f030e4bf914a0c0ad929b231'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
