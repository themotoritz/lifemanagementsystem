class AddDefaultValueToDone < ActiveRecord::Migration[7.1]
  def change
    change_column_default :events, :done, false
  end
end
