class AddReplyToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :reply, :text
  end

  def self.down
    remove_column :statuses, :reply
  end
end
