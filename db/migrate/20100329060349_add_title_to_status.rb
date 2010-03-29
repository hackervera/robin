class AddTitleToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :title, :text
  end

  def self.down
    remove_column :statuses, :title
  end
end
