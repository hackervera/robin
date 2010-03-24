class AddSubscriptionsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :subscriptions, :text
  end

  def self.down
    remove_column :users, :subscriptions
  end
end
