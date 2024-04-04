class Timeslot < ApplicationRecord
  belongs_to :event, optional: true
  
  validates :size, :start_time, :end_time, presence: true

  scope :is_free, -> { where(event_id: nil) }

  before_save :update_size

  def update_size
    self.size = end_time - start_time
  end

  def self.now
    where("start_time < ?", Time.now).where("end_time > ?", Time.now)
  end

  def self.update_current_timeslot
    if Timeslot.now.count > 1
      raise "FATAL: should not be possible"
    end

    current_timeslot =  Timeslot.now

    if current_timeslot.present?
      if current_timeslot.end_time > Time.now + 5.minutes
        current_timeslot.update(start_time: Time.now + 5.minutes)
      elsif current_timeslot.end_time <= Time.now + 5.minutes
        current_timeslot.destroy
      else
        raise "FATAL: case not covered"
      end
    end
  end
end
