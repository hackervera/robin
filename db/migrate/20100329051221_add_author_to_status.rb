class AddAuthorToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :author, :text
  end

  def self.down
    remove_column :statuses, :author
  end
end
