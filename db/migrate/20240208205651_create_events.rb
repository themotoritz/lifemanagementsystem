class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      t.string :type
      t.datetime :start_time
      t.integer :duration
      t.boolean :fixed

      t.timestamps
    end
  end
end
