class Event < ApplicationRecord
  enum :recurrence, { onetime: 0, daily: 1, twoday: 2, threeday: 3, fourday: 4, fiveday: 5, sixday: 6, weekly: 7, twoweek: 8, threeweek: 9, monthly: 10, twomonth: 11, threemonth: 12, fourmonth: 13, fivemonth: 14, sixmonth: 15, sevenmonth: 16, eightmonth: 17, ninemonth: 18, tenmonth: 19, elevenmonth: 20, yearly: 21, weekdays: 22, weekend: 23 }, prefix: true

  require 'csv'

  has_many :timeslots, dependent: :nullify
  has_one_attached :upload

  #validate :start_time_not_in_the_past, if: -> { start_time_changed? }
  #validate :start_time_before_end_time, if: -> { start_time_changed? || end_time_changed? }
  validate :duration_positiv, if: -> { duration_changed? }, unless: :archived?
  validate :no_overlapping_events_exist, if: -> { start_time_changed? || end_time_changed? || duration_changed? }, unless: :archived?
  after_destroy :merge_surrounding_timeslots
  after_commit :destroy_obsolete_timeslots
  before_save :set_default_priority, unless: :archived?
  before_save :update_bordering_timeslots, unless: :archived?

  scope :done, -> { where(done: true) }
  scope :undone, -> { where.not(done: true) }
  scope :archived, -> { where(archived: true) }
  scope :past, -> { where("start_time < ?", Time.now) }
  scope :future, -> { where("start_time >= ?", Time.now) }
  scope :not_blocking, -> { where("kind != ? OR kind IS NULL", "blocking") }
  scope :not_fixed, -> { where(fixed_date: false) }

  def self.current
    find_by("start_time < ? AND end_time > ?", Time.now, Time.now)
  end

  def self.next
    order(:start_time).first
  end

  def self.export_to_csv
    attributes = ["kind", "start_time", "end_time", "duration", "fixed", "description", "title", "done", "recurrence", "group_id", "priority", "project", "fixed_date", "result"]
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |record|
        csv << attributes.map{ |attr| record.send(attr) }
      end
    end
  end

  def self.get_group_id
    if where.not(group_id: nil).last.present?
      where.not(group_id: nil).order(:group_id).last.group_id + 1
    else
      1
    end
  end

  private

  def update_bordering_timeslots
    if start_time.present?
      unless start_time < Time.current
        if Timeslot.where("start_time <= ? AND end_time >= ?", start_time, end_time).count > 1
          raise "Should not be possible 1"
        end

        available_timeslot = Timeslot.find_by("start_time <= ? AND end_time >= ?", start_time, end_time)

        if available_timeslot.nil?
          raise "Should not be possible 2"
        end

        ts_start_time = available_timeslot.start_time
        ts_end_time = available_timeslot.end_time

        available_timeslot.destroy

        Timeslot.create(start_time: ts_start_time, end_time: start_time, size: start_time - ts_start_time)
        Timeslot.create(start_time: end_time, end_time: ts_end_time, size: ts_end_time - end_time)
      end
    end
  end

  def set_default_priority
    if priority.blank?
      self.priority = 50
    end
  end

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
        errors.add(:start_time, "Event-Titel '#{title}', #{start_time} (Startzeit) - #{end_time} (Endzeit) is within another event's time frame: #{overlapping_events.all.each {|event| puts event}}")
        self.start_time = self.end_time = self.duration = nil
      end
    end
  end

  def merge_surrounding_timeslots
    Timeslot.update_bordering_timeslots_before_destroying(self)
  end

  def destroy_obsolete_timeslots
    Timeslot.past.where("end_time < ?", Time.now).destroy_all
    Timeslot.where(size: 0).destroy_all
  end

  def self.project_names
    pluck(:project).compact.uniq.select { |element| !element.empty? }
  end
end
