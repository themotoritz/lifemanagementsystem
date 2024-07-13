class AddLackOfMotivationReasonToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :lack_of_motivation_reason, :string
  end
end
