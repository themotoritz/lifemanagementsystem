class Timeslot < ApplicationRecord
  belongs_to :event, optional: true
  
  validates :size, :start_time, :end_time, presence: true

  scope :is_free, -> { where(event_id: nil) }
  scope :past, -> { where("start_time < ?", Time.now) }

  before_save :update_size

  def update_size
    self.size = end_time - start_time
  end

  def self.current
    find_by("start_time < ? AND end_time > ?", Time.now, Time.now)
  end

  def self.next
    order(:start_time).first
  end

  def self.update_current_timeslot
    current_timeslot = Timeslot.current

    if current_timeslot.present?
      current_timeslot.update_or_destroy_if_too_small
    end
  end

  def update_or_destroy_if_too_small
    bigger_than_5_minutes = end_time > Time.now + 5.minutes
    smaller_than_5_minutes = end_time <= Time.now + 5.minutes

    if bigger_than_5_minutes
      postpone_by(5.minutes)
    elsif smaller_than_5_minutes
      destroy!
    else
      raise "FATAL: case not covered"
    end
  end

  def postpone_by(interval)
    update!(start_time: Time.now + interval)
  end

  def trim(new_end_time:)
    update!(end_time: new_end_time, size: end_time - start_time)
  end

  def self.destroy_past_timeslots
    Timeslot.past.where("end_time < ?", Time.now).destroy_all
    Timeslot.where(size: 0).destroy_all
  end

  def self.update_surrounding_timeslots_one(id)
    event_start_time = Event.find(id).start_time
    event_end_time = Event.find(id).end_time
    
    closest_previous_timeslot = Timeslot.where("end_time <= ?", event_start_time).order(:start_time).last
    closest_subsequent_timeslot = Timeslot.where("start_time >= ?", event_end_time).order(:start_time).first

    if closest_previous_timeslot.present?
      new_end_time = closest_subsequent_timeslot.end_time
      closest_subsequent_timeslot.destroy if closest_subsequent_timeslot.present?
      closest_previous_timeslot.update(end_time: new_end_time)
    elsif closest_subsequent_timeslot.present?
      closest_subsequent_timeslot.update(start_time: event_start_time)
    end
  end
end
