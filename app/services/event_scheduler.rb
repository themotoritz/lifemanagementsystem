class EventScheduler
  def initialize(events)    
    @events = Array(events)

    p "time current 1.1: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    @calendar = Calendar.new
    p "time current 1.2: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
  end

  def call
    #p "time current 2.1: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    unschedule_events_from_calendar
    #p "time current 2.2: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    @calendar.get_timeslots
    #p "time current 3.1: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    schedule_events
    #p "time current 3.2: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    save_events

    if @events.length == 1
      return @events.first
    else
      return @events
    end
  end

  def unschedule_events_from_calendar
    @calendar.events -= @events
  end

  def schedule_events
    count_spent_time = 0

    @events.each do |event|
      if event.fixed_date == true || event.fixed_time == true
        if event.start_time >= Time.current
          timeslot, timeslot_index = @calendar.get_next_suitable_timeslot(event: event, date: event.start_time.to_date)

          if timeslot.present?
            # event.start_time = event.fixed_datetime_at # not sure why I did it like that
            event.start_time = timeslot.start_time 
            event.end_time = event.start_time + event.duration
          else
            raise "no timeslot found"
          end
        end
      else
        timeslot, timeslot_index = @calendar.get_next_suitable_timeslot(event: event)

        event.start_time = timeslot.start_time
        event.end_time = timeslot.start_time + event.duration
      end
      
      #p "time current 3.1.1.1: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
      closest_event, index = @calendar.get_closest_event(events: @calendar.events, given_time: event.start_time)
      #p "time current 3.1.1.2: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
      if closest_event.start_time < event.start_time 
        @calendar.events.insert(index+1, event) # ging hier garnicht durch
      else
        @calendar.events.insert(index, event)
      end

      #@calendar.get_events
      #p "time current 3.1.2.1: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
      before = Time.current
      #@calendar.get_timeslots
      @calendar.timeslots[timeslot_index].start_time = event.end_time
      @calendar.timeslots[timeslot_index].size = @calendar.timeslots[timeslot_index].end_time - @calendar.timeslots[timeslot_index].start_time
      afterwards = Time.current
      count_spent_time += (afterwards - before)
      #p "time current 3.1.2.2: #{Time.current.strftime("%Y-%m-%d %H:%M:%S.%L %z")}"
    end

    #p "spent time: #{count_spent_time}"
  end
  
  def get_available_timeslot
    @timeslot_start_time = Time.current + 5.minutes
    @timeslot_end_time = @next_event.start_time
    @timeslot_duration = @timeslot_end_time - @timeslot_start_time
  end

  def save_events
    @events.each do |event|
      if event.persisted? 
        event.update_columns(
          start_time: event.start_time,
          end_time: event.end_time
        )
      end
    end
  end
end