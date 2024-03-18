class Event < ApplicationRecord
  has_many :timeslots, dependent: :nullify

  before_save :set_defaults
  

  private  
  
  def set_defaults
    duration ||= 15
    fixed ||= false

    if start_time.present?
      timeslots << Timeslot.find_by(start_time: start_time)
    else
      timeslots << find_next_free_timeslots
      start_time = timeslots.first.start_time
    end
  end

  def find_next_free_timeslots
    Timeslot.is_free.first
  end
end
