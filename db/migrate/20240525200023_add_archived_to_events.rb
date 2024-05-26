class AddArchivedToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :archived, :boolean, default: false
  end
end
