class SingleEventScheduler
  def initialize(event)
    @event = event
  end

  def schedule(destroy_past_timeslots: false, first_record: false)
    Timeslot.destroy_past_timeslots if destroy_past_timeslots
    Timeslot.update_current_timeslot if first_record == true

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = find_free_timeslot
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    if !timeslot.present?
      raise "unknown case"
    end

    return @event
  end

  def schedule_only_day(date, destroy_past_timeslots: false, first_record: false)
    Timeslot.destroy_past_timeslots if destroy_past_timeslots
    Timeslot.update_current_timeslot if first_record == true

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = schedule_only_day_find_free_timeslot(date)
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end
    
    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    if !timeslot.present?
      raise "unknown case"
    end
    
    return @event
  end

  def schedule_only_day_find_free_timeslot(date)
    timeslots = Timeslot.order(:start_time).where("size >= ?", @event.duration)

    timeslot = timeslots.where(start_time: date.beginning_of_day..date.end_of_day).first || find_free_timeslot

    timeslot
  end

  def find_free_timeslot
    timeslots = Timeslot.order(:start_time).where("size >= ?", @event.duration)

    if @event.start_time.present? 
      timeslot = timeslots.where("start_time <= ?", @event.start_time).where("end_time >= ?", @event.end_time || @event.start_time + @event.duration).first
    elsif @event.duration.present?
      timeslot = timeslots.where("end_time >= ?", Time.current).first
    else
      raise "FATAL: case not covered"
    end

    timeslot
  end
end