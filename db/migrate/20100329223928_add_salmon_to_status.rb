class AddSalmonToStatus < ActiveRecord::Migration
  def self.up
    add_column :statuses, :salmon, :text
  end

  def self.down
    remove_column :statuses, :salmon
  end
end
