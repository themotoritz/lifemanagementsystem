class AddIndicesToTimeslot < ActiveRecord::Migration[6.1]
  def change
    add_index :timeslots, :start_time
    add_index :timeslots, :end_time
    add_index :timeslots, :size
  end
end