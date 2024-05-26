class AddDoneAtTimestampToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :done_at, :datetime
  end
end
