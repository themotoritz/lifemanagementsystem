class AddFixedDateAtAndFixedDateTimeAtToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :fixed_date_at, :date
    add_column :events, :fixed_datetime_at, :datetime
  end
end
