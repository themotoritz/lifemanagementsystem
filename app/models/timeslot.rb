class Timeslot < ApplicationRecord
  belongs_to :event, optional: true

  validates :size, :start_time, :end_time, presence: true
  before_save :no_overlapping_timeslots_exist

  scope :is_free, -> { where(event_id: nil) }
  scope :past, -> { where("start_time < ?", Time.now) }

  before_save :update_size

  def no_overlapping_timeslots_exist
    if start_time.present?
      overlapping_timeslots = Timeslot.where.not(id: id).where("start_time < ? AND end_time > ?", end_time, start_time)
      if overlapping_timeslots.any?
        errors.add(:start_time, "Timeslot-ID '#{id}', #{start_time} (Startzeit) - #{end_time} (Endzeit) is within another timeslot's time frame: #{overlapping_timeslots.all.each {|timeslot| puts timeslot}}")
        self.start_time = self.end_time = self.size = nil
      end
    end
  end

  def update_size
    self.size = end_time - start_time
  end

  def self.current
    time_current = Time.current
    find_by("start_time < ? AND end_time > ?", time_current, time_current)
  end

  def self.next
    order(:start_time).first
  end

  def self.update_current_timeslot
    current_timeslot = Timeslot.current
    current_timeslot.update_or_destroy_if_too_small if current_timeslot.present?
  end

  def update_or_destroy_if_too_small
    time_current = Time.current
    bigger_than_5_minutes = end_time > time_current + 5.minutes
    smaller_than_5_minutes = end_time <= time_current+ 5.minutes

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

  def self.destroy_past_timeslots
    Timeslot.where("(end_time < ?) OR (size = 0)", Time.now).destroy_all
  end

  def self.update_bordering_timeslots_before_destroying(event)
    skip_save = false
    new_timeslot = Timeslot.new(start_time: event.start_time, end_time: event.end_time, size: event.end_time - event.start_time)

    ## merge bordering timeslots
    previous_bordering_timeslot = Timeslot.find_by(end_time: new_timeslot.start_time)
    subsequent_bordering_timeslot = Timeslot.find_by(start_time: new_timeslot.end_time)

    if previous_bordering_timeslot.present? && subsequent_bordering_timeslot.present?
      previous_bordering_timeslot_start_time = previous_bordering_timeslot.start_time
      subsequent_bordering_timeslot_end_time = subsequent_bordering_timeslot.end_time

      previous_bordering_timeslot.destroy
      subsequent_bordering_timeslot.destroy

      new_timeslot.update(start_time: previous_bordering_timeslot_start_time, end_time: subsequent_bordering_timeslot_end_time)
    elsif previous_bordering_timeslot.present? && subsequent_bordering_timeslot.nil?
      previous_bordering_timeslot_start_time = previous_bordering_timeslot.start_time

      previous_bordering_timeslot.destroy

      new_timeslot.update(start_time: previous_bordering_timeslot_start_time)
    elsif previous_bordering_timeslot.nil? && subsequent_bordering_timeslot.present?
      subsequent_bordering_timeslot_end_time = subsequent_bordering_timeslot.end_time

      subsequent_bordering_timeslot.destroy

      new_timeslot.update(end_time: subsequent_bordering_timeslot_end_time)
    else
      overlapping_timeslot = Timeslot.find_by("start_time < ? AND end_time > ?", event.end_time, event.start_time)

      if overlapping_timeslot.present?
        if overlapping_timeslot.end_time >= event.end_time && overlapping_timeslot.start_time <= event.start_time
          # do not create timeslot
          skip_save = true
        elsif overlapping_timeslot.end_time >= event.end_time
          raise "unknown case"
        elsif overlapping_timeslot.start_time <= event.start_time
          raise "unknown case"
        end
      end
    end

    unless skip_save == true
      new_timeslot.save
    end
  end
end
