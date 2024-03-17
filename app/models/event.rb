class Event < ApplicationRecord
  has_many :timeslots, dependent: :nullify

  before_save :set_defaults
  

  private  
  
  def set_defaults
    self.duration ||= 15
    self.fixed ||= false

    if self.start_time.present?
      self.timeslots << Timeslot.find_by(start_time: start_time)
    else
      self.timeslots << find_next_free_timeslots
      self.start_time = self.timeslots.first.start_time
    end
  end

  def find_next_free_timeslots
    Timeslot.is_free.first
  end
end
