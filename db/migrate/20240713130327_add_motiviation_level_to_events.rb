class AddMotiviationLevelToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :motivation_level, :integer, default: 50
  end
end