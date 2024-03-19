class Event < ApplicationRecord
  has_many :timeslots, dependent: :nullify

  # before_save :find_free_timeslot
  # validate start_time before end_time

  before_validation :schedule
  validate :start_time_not_in_the_past
  validate :start_time_before_end_time
  validate :duration_positiv
  validate :no_overlapping_events_exist
  after_destroy :merge_surrounding_timeslots
  after_commit :destroy_obsolete_timeslots

  private

  def start_time_before_end_time
    if start_time.present? && end_time.present? && start_time >= end_time
      errors.add(:start_time, "must be prior to end time")
    end
  end

  def duration_positiv
    if duration.present? && duration < 0
      errors.add(:duration, "must not be negativ")
    end
  end

  def start_time_not_in_the_past
    if start_time.present? && start_time < Time.now
      errors.add(:start_time, "must not be in the past")
    end
  end

  def no_overlapping_events_exist
    if start_time.present?
      overlapping_events = Event.where.not(id: id).where("start_time < ? AND end_time > ?", end_time, start_time)
      if overlapping_events.any?
        errors.add(:start_time, "is within another event's time frame")
        self.start_time = self.end_time = self.duration = nil
      end
    end
  end

  def schedule
    if Timeslot.where("start_time < ?", Time.now).where("end_time > ?", Time.now).count > 1
      raise "FATAL: should not be possible"
    end

    current_timeslot =  Timeslot.where("start_time < ?", Time.now).where("end_time > ?", Time.now).first

    if current_timeslot.present?
      if current_timeslot.end_time > Time.now + 5.minutes
        current_timeslot.update(start_time: Time.now + 5.minutes)
      elsif current_timeslot.end_time <= Time.now + 5.minutes
        current_timeslot.destroy
      else
        raise "FATAL: case not covered"
      end
    end

    timeslot = nil

    if start_time.nil? && end_time.nil? && duration.nil?
      self.duration = 15.minutes
      timeslot = find_free_timeslot
      self.start_time = timeslot.start_time
      self.end_time = start_time + duration
    elsif start_time.nil? && end_time.nil? && duration.present?
      timeslot = find_free_timeslot
      self.start_time = timeslot.start_time
      self.end_time = start_time + duration
    elsif start_time.present? && end_time.nil? && duration.nil?
      self.duration = 15.minutes
      timeslot = find_free_timeslot
      self.end_time = start_time + duration
    elsif start_time.present? && end_time.nil? && duration.present?
      timeslot = find_free_timeslot
      self.end_time = start_time + duration
    # elsif start_time.present? && end_time.present? && duration.nil?
    #   self.duration = end_time - start_time
    end

    if timeslot.present?
      udpate_timeslots(timeslot)
    else
      raise "FATAL: case not covered"
    end
  end

  def find_free_timeslot
    if start_time.present? 
      timeslot = Timeslot.order(:start_time).where("size > ?", duration).where("start_time <= ?", start_time).where("end_time >= ?", end_time || start_time + duration).first
    elsif duration.present?
      timeslot = Timeslot.order(:start_time).where("size > ?", duration).where("end_time >= ?", Time.now).first
    else
      raise "FATAL: case not covered"
    end

    unless timeslot.present?
      errors.add(:start_time, "Keinen freien Time Slot gefunden")
      self.start_time = self.end_time = self.duration = nil
    end

    timeslot
  end

  def udpate_timeslots(timeslot)
    timeslot_start_time = timeslot.start_time
    timeslot_end_time = timeslot.end_time

    timeslot.update(end_time: start_time, size: start_time - timeslot_start_time)
    Timeslot.create!(start_time: end_time, end_time: timeslot_end_time, size: timeslot_end_time - start_time)
  end

  def merge_surrounding_timeslots
    closest_previous_timeslot = Timeslot.where("end_time < ?", start_time).order(:start_time).last
    closest_subsequent_timeslot = Timeslot.where("start_time > ?", end_time).order(:start_time).first

    new_end_time = closest_subsequent_timeslot.end_time
    closest_subsequent_timeslot.destroy
    closest_previous_timeslot.update(end_time: new_end_time)
  end

  def destroy_obsolete_timeslots
    Timeslot.where("start_time < ?", Time.now).where("end_time < ?", Time.now).destroy_all
    Timeslot.where(size: 0).destroy_all
  end
end