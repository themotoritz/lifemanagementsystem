class Calendar
  attr_accessor :events, :timeslots, :next_suitable_timeslot

  def initialize
    get_events
  end

  def get_events
    @events = Event.future.undone.order(:start_time).to_a
  end
  
  def get_timeslots
    @timeslots = []

    (0..@events.count-2).each do |index|
      time_current = Time.current

      if index == 0 && ((@events[index].start_time - time_current) >= 5.minutes)
        timeslot_size = @events[index].start_time - time_current
        @timeslots << Timeslot.new(start_time: time_current + 5.minutes, end_time: @events[index].start_time, size: timeslot_size)
      end
      
      this_event_end_time = @events[index].end_time
      next_event_start_time = @events[index+1].start_time
      timeslot_size = next_event_start_time - this_event_end_time

      if timeslot_size == 0
        next
      else
        @timeslots << Timeslot.new(start_time: this_event_end_time, end_time: next_event_start_time, size: timeslot_size)
      end
    end
  end

  def get_next_suitable_timeslot(size:, date: nil)
    get_timeslots if @timeslots.empty?
    i = nil

    @timeslots.each_with_index do |timeslot, index|
      if date.present?
        if timeslot.size >= size && timeslot.start_time.to_date == date
          @next_suitable_timeslot = timeslot
          i = index
          
          break
        end
      else
        if timeslot.size >= size
          @next_suitable_timeslot = timeslot
          i = index
          
          break
        end
      end
    end

    [@next_suitable_timeslot, i]
  end

  def get_closest_event(events:, given_time:)
    return nil if events.empty?
  
    low = 0
    high = events.size - 1
  
    while low < high
      mid = (low + high) / 2
      if events[mid].start_time < given_time
        low = mid + 1
      else
        high = mid
      end
    end
  
    closest_event = events[low]
  
    [closest_event, low]
  end  
end