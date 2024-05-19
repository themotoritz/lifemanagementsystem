class AddProjectToEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :project, :string
  end
end
