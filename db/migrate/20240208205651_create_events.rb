class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :kind
      t.datetime :start_time
      t.datetime :end_time
      t.integer :duration
      t.boolean :fixed
      t.text :description
      t.string :title
      t.boolean :done

      t.timestamps
    end
  end
end