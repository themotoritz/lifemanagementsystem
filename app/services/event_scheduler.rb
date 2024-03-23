class EventScheduler
  def initialize(event)
    @event = event
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

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = find_free_timeslot
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    udpate_timeslots(timeslot) if timeslot.present?

    return @event
  end

  def schedule_only_day(date)
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

    if @event.end_time.nil?
      @event.duration = 15.minutes if @event.duration.nil?
      timeslot = schedule_only_day_find_free_timeslot(date)
      @event.start_time = timeslot.start_time if (timeslot.present? && !@event.start_time.present?)
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    udpate_timeslots(timeslot) if timeslot.present?

    return @event
  end

  def schedule_only_day_find_free_timeslot(date)
    timeslots = Timeslot.order(:start_time).where("size > ?", @event.duration)

    timeslot = timeslots.where(start_time: date.beginning_of_day..date.end_of_day).first

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

  def udpate_timeslots(timeslot)
    timeslot_start_time = timeslot.start_time
    timeslot_end_time = timeslot.end_time

    timeslot.update(end_time: @event.start_time, size: @event.start_time - timeslot_start_time)
    Timeslot.create!(start_time: @event.end_time, end_time: timeslot_end_time, size: timeslot_end_time - @event.start_time)
  end
end