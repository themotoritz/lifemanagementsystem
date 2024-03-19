class CreateTimeslots < ActiveRecord::Migration[7.1]
  def change
    create_table :timeslots do |t|
      t.bigint :size
      t.datetime :start_time
      t.datetime :end_time
      t.belongs_to :event, foreign_key: true

      t.timestamps
    end
  end
end
