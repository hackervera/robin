class AddToToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :to, :text
  end

  def self.down
    remove_column :statuses, :to
  end
end
