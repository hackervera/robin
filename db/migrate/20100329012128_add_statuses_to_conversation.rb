class AddStatusesToConversation < ActiveRecord::Migration
  def self.up
    add_column :conversations, :statuses, :text
  end

  def self.down
    remove_column :conversations, :statuses
  end
end
