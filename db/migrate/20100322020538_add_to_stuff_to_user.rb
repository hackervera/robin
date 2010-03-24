class AddToStuffToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :password, :text
    add_column :users, :email, :text
    add_column :users, :foaf_location, :text
    add_column :users, :username, :text
    add_column :users, :picture_url, :text
    add_column :users, :host, :text
    add_column :users, :profile_url, :text
  end

  def self.down
    remove_column :users, :profile_url
    remove_column :users, :host
    remove_column :users, :picture_url
    remove_column :users, :username
    remove_column :users, :foaf_location
    remove_column :users, :email
    remove_column :users, :password
  end
end
