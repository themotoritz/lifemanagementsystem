class AddFixedDateToEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :fixed_date, :boolean, default: false
  end
end
