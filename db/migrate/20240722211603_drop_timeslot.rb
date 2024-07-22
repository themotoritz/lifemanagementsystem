class DropTimeslot < ActiveRecord::Migration[7.1]
  def up
    drop_table :timeslots
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
