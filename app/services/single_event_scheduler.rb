class SingleEventScheduler
  def initialize(event)
    @event = event
  end

  def schedule
    Timeslot.update_current_timeslot

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = find_free_timeslot
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    update_surrounding_timeslots(timeslot) if timeslot.present?

    return @event
  end

  def schedule_only_day(date)
    Timeslot.update_current_timeslot

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = schedule_only_day_find_free_timeslot(date)
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    update_surrounding_timeslots(timeslot) if timeslot.present?

    return @event
  end

  def schedule_only_day_find_free_timeslot(date)
    timeslots = Timeslot.order(:start_time).where("size > ?", @event.duration)

    timeslot = timeslots.where(start_time: date.beginning_of_day..date.end_of_day).first || find_free_timeslot

    timeslot
  end

  def find_free_timeslot
    timeslots = Timeslot.order(:start_time).where("size > ?", @event.duration)

    if @event.start_time.present? 
      timeslot = timeslots.where("start_time <= ?", @event.start_time).where("end_time >= ?", @event.end_time || @event.start_time + @event.duration).first
    elsif @event.duration.present?
      timeslot = timeslots.where("end_time >= ?", Time.now).first
    else
      raise "FATAL: case not covered"
    end

    timeslot
  end

  def update_surrounding_timeslots(current_timeslot)
    new_timeslot_end_time = current_timeslot.end_time
    current_timeslot.trim(new_end_time: @event.start_time)
    create_new_timeslot_after_event(start_time: @event.end_time, end_time: new_timeslot_end_time)
  end

  def create_new_timeslot_after_event(start_time:, end_time:)
    Timeslot.create!(start_time: start_time, end_time: end_time, size: end_time - start_time)
  end
end