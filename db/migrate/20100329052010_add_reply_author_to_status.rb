class AddReplyAuthorToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :reply_author, :text
  end

  def self.down
    remove_column :statuses, :reply_author
  end
end
