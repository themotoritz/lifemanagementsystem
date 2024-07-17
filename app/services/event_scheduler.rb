class EventScheduler
  def initialize(events)
    @events = events
    @calendar = Calendar.new
  end

  def call
    unschedule_events_from_calendar
    
    calendar_get_next_event
    
    get_available_timeslot
    #schedule_events
  end

  def unschedule_events_from_calendar
    @events.each do |event|
      e = @calendar.events.find { |e| e.id == event.id}
      e.start_time = nil
      e.end_time = nil
    end
  end

  def calendar_get_next_event
    @next_event = @calendar.events.find { |event| event.start_time != nil && event.start_time > Time.current }
  end
  
  def get_available_timeslot
    @timeslot_start_time = Time.current + 5.minutes
    @timeslot_end_time = @next_event.start_time
    @timeslot_duration = @timeslot_end_time - @timeslot_start_time
  end

  def schedule_events
    if @timeslot_duration >= @event.duration
      @events.first.start_time = @timeslot_start_time
    end
  end
end