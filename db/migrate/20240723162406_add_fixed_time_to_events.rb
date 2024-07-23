class AddFixedTimeToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :fixed_time, :boolean, default: false
  end
end
