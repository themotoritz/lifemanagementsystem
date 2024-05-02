class AddPriorityToEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :priority, :integer, default: 50
  end
end
