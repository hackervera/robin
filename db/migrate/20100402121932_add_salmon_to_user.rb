class AddSalmonToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :salmon, :text
  end

  def self.down
    remove_column :users, :salmon
  end
end
