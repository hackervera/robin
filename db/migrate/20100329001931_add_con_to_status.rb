class AddConToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :conversation, :text
  end

  def self.down
    remove_column :statuses, :conversation
  end
end
