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

  def udpate_timeslots(timeslot)
    timeslot_start_time = timeslot.start_time
    timeslot_end_time = timeslot.end_time

    timeslot.update(end_time: @event.start_time, size: @event.start_time - timeslot_start_time)
    Timeslot.create!(start_time: @event.end_time, end_time: timeslot_end_time, size: timeslot_end_time - @event.start_time)
  end

  def create_remaining_events(date, time)
    events = []

    case @event.recurrence
    when "daily"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 1.day
      day_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + day_counter.days
        end
        events << event
    
        current_time += 1.day
        day_counter += 1
      end
    when "twoday"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 2.days
      two_day_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (two_day_counter * 2).days
        end
        events << event
    
        current_time += 2.days
        two_day_counter += 1
      end    
    when "threeday"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 3.days
      three_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (three_day_counter * 3).days
        end
        events << event

        current_time += 3.days
        three_day_counter += 1
      end
    when "fourday"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 4.days
      four_day_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (four_day_counter * 4).days
        end
        events << event
    
        current_time += 4.days
        four_day_counter += 1
      end
    when "fiveday"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 5.days
      five_day_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (five_day_counter * 5).days
        end
        events << event
    
        current_time += 5.days
        five_day_counter += 1
      end
    when "sixday"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 6.days
      six_day_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (six_day_counter * 6).days
        end
        events << event
    
        current_time += 6.days
        six_day_counter += 1
      end
    when "weekly"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 1.week
      week_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + week_counter.week
        end
        events << event

        current_time += 1.week
        week_counter += 1
      end
    when "twoweek"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 2.weeks
      two_week_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (two_week_counter * 2).weeks
        end
        events << event

        current_time += 2.weeks
        two_week_counter += 1
      end
    when "threeweek"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 3.weeks
      three_week_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (three_week_counter * 3).weeks
        end
        events << event
    
        current_time += 3.weeks
        three_week_counter += 1
      end
    when "monthly"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 1.month
      month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + month_counter.month
        end
        events << event

        current_time += 1.month
        month_counter += 1
      end  
    when "twomonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 2.months
      two_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (two_month_counter * 2).months
        end
        events << event
    
        current_time += 2.months
        two_month_counter += 1
      end
    when "threemonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 3.months
      three_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (three_month_counter * 3).months
        end
        events << event
    
        current_time += 3.months
        three_month_counter += 1
      end
    when "fourmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 4.months
      four_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (four_month_counter * 4).months
        end
        events << event
    
        current_time += 4.months
        four_month_counter += 1
      end    
    when "fivemonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 5.months
      five_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (five_month_counter * 5).months
        end
        events << event
    
        current_time += 5.months
        five_month_counter += 1
      end
    when "sixmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 6.months
      six_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (six_month_counter * 6).months
        end
        events << event
    
        current_time += 6.months
        six_month_counter += 1
      end    
    when "sevenmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 7.months
      seven_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (seven_month_counter * 7).months
        end
        events << event
    
        current_time += 7.months
        seven_month_counter += 1
      end
    when "eightmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 8.months
      eight_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (eight_month_counter * 8).months
        end
        events << event
    
        current_time += 8.months
        eight_month_counter += 1
      end
    when "ninemonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 9.months
      nine_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (nine_month_counter * 9).months
        end
        events << event
    
        current_time += 9.months
        nine_month_counter += 1
      end
    when "tenmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 10.months
      ten_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (ten_month_counter * 10).months
        end
        events << event

        current_time += 10.months
        ten_month_counter += 1
      end
    when "elevenmonth"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 11.months
      eleven_month_counter = 1
    
      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + (eleven_month_counter * 11).months
        end
        events << event
    
        current_time += 11.months
        eleven_month_counter += 1
      end    
    when "yearly"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time + 1.year
      year_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        event.start_time = current_time
        if @event.end_time.present?
          event.end_time = @event.end_time + year_counter.year
        end
        events << event
    
        current_time += 1.year
        year_counter += 1
      end
    when "weekdays"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time.to_date + 1.day
    
      while current_time <= create_until_date
        # Check if the current day is a weekday (Monday to Friday)
        if current_time.wday >= 1 && current_time.wday <= 5  # Monday = 1, Friday = 5
          event = @event.dup
          event.start_time = current_time.to_time
          if @event.end_time.present?
            event.end_time = @event.end_time + 1.day
          end
          events << event
        end
    
        current_time += 1.day
      end
    when "weekend"
      events << @event 

      create_until_date = 10.years.from_now.end_of_month
      current_time = @event.start_time.to_date + 1.day
    
      while current_time <= create_until_date
        # Check if the current day is a weekend (Saturday or Sunday)
        if current_time.saturday? || current_time.sunday?
          event = @event.dup
          event.start_time = current_time.to_time
          if @event.end_time.present?
            event.end_time = @event.end_time + 1.day
          end
          events << event
        end
    
        current_time += 1.day
      end
    end

    events
  end
end