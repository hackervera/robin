class AddStuffToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :text, :text
  end

  def self.down
    remove_column :statuses, :text
  end
end
