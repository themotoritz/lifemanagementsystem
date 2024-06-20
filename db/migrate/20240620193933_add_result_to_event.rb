class AddResultToEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :result, :text
  end
end