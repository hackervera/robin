class AddToUserIdToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :user_id, :int
  end

  def self.down
    remove_column :statuses, :user_id
  end
end
