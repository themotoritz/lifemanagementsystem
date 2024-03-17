class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :kind
      t.datetime :start_time
      t.integer :duration
      t.boolean :fixed
      t.text :description
      t.string :title

      t.timestamps
    end
  end
end