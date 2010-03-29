class AddUrlToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :url, :text
  end

  def self.down
    remove_column :statuses, :url
  end
end
