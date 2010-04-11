class AddToToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :recip, :text
  end

  def self.down
    remove_column :statuses, :recip
  end
end
