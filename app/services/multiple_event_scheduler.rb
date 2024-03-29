class MultipleEventScheduler
  def initialize(event)
    @event = event
  end

  def create_events(date_param, time_param)
    events = []
    group_id = Event.get_group_id
    if group_id == nil || Event.where(group_id: group_id).present?
      raise "FATAL: should not be possible"
    end
    @event.update(group_id: group_id)
    events << @event 
    create_until_date = 10.years.from_now.end_of_month

    case @event.recurrence
    when "daily"
      current_time = @event.start_time.to_date

      while current_time <= create_until_date.to_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end
      
        events << event
      
        current_time += 1.day
      end      
    when "twoday"
      current_time = @event.start_time + 2.days
      two_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 2.days
        two_day_counter += 1
      end
    when "threeday"
      current_time = @event.start_time + 3.days
      three_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 3.days
        three_day_counter += 1
      end
    when "fourday"
      current_time = @event.start_time + 4.days
      four_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 4.days
        four_day_counter += 1
      end
    when "fiveday"
      current_time = @event.start_time + 5.days
      five_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 5.days
        five_day_counter += 1
      end
    when "sixday"
      current_time = @event.start_time + 6.days
      six_day_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 6.days
        six_day_counter += 1
      end
    when "weekly"
      current_time = @event.start_time + 1.week
      week_counter = 1
      
      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end
      
        events << event
      
        current_time += 1.week
        week_counter += 1
      end      
    when "twoweek"
      current_time = @event.start_time + 2.weeks
      two_week_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 2.weeks
        two_week_counter += 1
      end
    when "threeweek"
      current_time = @event.start_time + 3.weeks
      three_week_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 3.weeks
        three_week_counter += 1
      end
    when "monthly"
      current_time = @event.start_time + 1.month
      month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 1.month
        month_counter += 1
      end
    when "twomonth"
      current_time = @event.start_time.next_month.next_month
      two_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time = current_time.next_month.next_month
        two_month_counter += 1
      end
    when "threemonth"
      current_time = @event.start_time + 3.months
      three_month_counter = 1
      
      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end
      
        events << event
      
        current_time += 3.months
        three_month_counter += 1
      end      
    when "fourmonth"
      current_time = @event.start_time + 4.months
      four_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 4.months
        four_month_counter += 1
      end
    when "fivemonth"
      current_time = @event.start_time + 5.months
      five_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 5.months
        five_month_counter += 1
      end
    when "sixmonth"
      current_time = @event.start_time + 6.months
      six_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 6.months
        six_month_counter += 1
      end
    when "sevenmonth"
      current_time = @event.start_time + 7.months
      seven_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 7.months
        seven_month_counter += 1
      end
    when "eightmonth"
      current_time = @event.start_time + 8.months
      eight_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 8.months
        eight_month_counter += 1
      end
    when "ninemonth"
      current_time = @event.start_time + 9.months
      nine_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 9.months
        nine_month_counter += 1
      end
    when "tenmonth"
      current_time = @event.start_time + 10.months
      ten_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 10.months
        ten_month_counter += 1
      end
    when "elevenmonth"
      current_time = @event.start_time + 11.months
      eleven_month_counter = 1

      while current_time <= create_until_date
        event = @event.dup
        
        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 11.months
        eleven_month_counter += 1
      end
    when "yearly"
      current_time = @event.start_time + 1.year
      year_counter = 1

      while current_time <= create_until_date
        event = @event.dup

        if time_param.present?
          event.start_time = current_time
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule
        else
          event.end_time = event.start_time = nil
          event_scheduler = SingleEventScheduler.new(event)
          event = event_scheduler.schedule_only_day(current_time.to_date)
        end

        events << event

        current_time += 1.year
        year_counter += 1
      end
    when "weekdays"
      current_time = @event.start_time + 1.day

      while current_time <= create_until_date
        # Skip weekends (Saturday and Sunday)
        unless current_time.saturday? || current_time.sunday?
          event = @event.dup
      
          if time_param.present?
            event.start_time = current_time
            event_scheduler = SingleEventScheduler.new(event)
            event = event_scheduler.schedule
          else
            event.end_time = event.start_time = nil
            event_scheduler = SingleEventScheduler.new(event)
            event = event_scheduler.schedule_only_day(current_time.to_date)
          end
      
          events << event
        end
      
        current_time += 1.day
      end      
    when "weekend"
      current_time = @event.start_time + 1.day

      while current_time <= create_until_date
        # Include weekends (Saturday and Sunday)
        if current_time.saturday? || current_time.sunday?
          event = @event.dup
      
          if time_param.present?
            event.start_time = current_time
            event_scheduler = SingleEventScheduler.new(event)
            event = event_scheduler.schedule
          else
            event.end_time = event.start_time = nil
            event_scheduler = SingleEventScheduler.new(event)
            event = event_scheduler.schedule_only_day(current_time.to_date)
          end
      
          events << event
        end

        current_time += 1.day
      end
    end

    events
  end
end