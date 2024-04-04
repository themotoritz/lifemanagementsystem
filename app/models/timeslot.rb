class Timeslot < ApplicationRecord
  belongs_to :event, optional: true
  
  validates :size, :start_time, :end_time, presence: true

  scope :is_free, -> { where(event_id: nil) }

  before_save :update_size

  def update_size
    self.size = end_time - start_time
  end

  def self.current_timeslot
    where("start_time < ?", Time.now).where("end_time > ?", Time.now)
  end
end
