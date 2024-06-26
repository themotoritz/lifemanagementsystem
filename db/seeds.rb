Timeslot.create(start_time: Time.now, end_time: 20.years.from_now.end_of_day, size: 20.years.from_now.end_of_day - Time.now)


sleeping_time = Time.zone.parse("00:00 AM")
lunch_time = Time.zone.parse("12:00 PM")

# Define the duration of one day
one_day = 1.day

# Define the number of years for which you want to create events
years = 20

# Loop through each day for the next 100 years and create the event
(1..(365 * years)).each do |day_offset|
  current_date = Time.zone.now + day_offset.days
  sleeping_datetime = sleeping_time + day_offset.days
  lunch_datetime = lunch_time + day_offset.days
  
  # Skip weekends (Saturday and Sunday)
  if current_date.saturday? || current_date.sunday?
    event = Event.new(
      title: "Schlafen + Frühstück",
      description: "Sleeping Hours",
      start_time: sleeping_datetime,
      duration: 9.hours,
      kind: "blocking",
      fixed: false,
      done: false,
      archived: false
    )

    event_scheduler = SingleEventScheduler.new(event)
    event = event_scheduler.schedule
    event.save!

    event = Event.new(
      title: "Mittagspause",
      description: "Mittagspause",
      start_time: lunch_datetime,
      duration: 2.hours,
      kind: "blocking",
      fixed: false,
      done: false,
      archived: false
    )

    event_scheduler = SingleEventScheduler.new(event)
    event = event_scheduler.schedule
    event.save!
  else
    event = Event.new(
      title: "Schlafen und Arbeit",
      description: "Sleeping Hours and Work",
      start_time: sleeping_datetime,
      duration: 17.hours+30.minutes,
      kind: "blocking",
      fixed: false,
      done: false,
      archived: false
    )

    event_scheduler = SingleEventScheduler.new(event)
    event = event_scheduler.schedule
    event.save!
  end
end


# timeslot_size = 15
# length_of_day_in_minutes = 60*24
# amount_of_timeslots_each_day = length_of_day_in_minutes / timeslot_size

# remaining_minutes_til_midnight = (Time.zone.now.end_of_day - Time.zone.now)/60
# remaining_minutes_til_midnight = remaining_minutes_til_midnight.round(0)
# amount_of_timeslots_today = remaining_minutes_til_midnight/timeslot_size

# minutes_since_beginning_of_day = (Time.zone.now - Time.zone.now.beginning_of_day)/60
# past_timeslots = (minutes_since_beginning_of_day/timeslot_size).floor
# next_timeslot = past_timeslots+1

# amount_of_timeslots_before = Timeslot.count
# (next_timeslot..amount_of_timeslots_each_day-1).each do |timeslot|
#   next_timeslot_time = Time.zone.now.beginning_of_day + timeslot*timeslot_size.minutes
#   start_time = next_timeslot_time
#   end_time = next_timeslot_time + timeslot_size.minutes

#   Timeslot.create!(start_time: start_time, end_time: end_time, size: timeslot_size)
# end
# amount_of_timeslots_afterwards = Timeslot.count
# amount_of_timeslots_created = amount_of_timeslots_afterwards - amount_of_timeslots_before
# p "#{Date.today.strftime("%A %d.%m")}: created #{amount_of_timeslots_created} timeslots"

# # ---

# days_of_week = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
# current_day = Date.today.strftime('%A').downcase
# current_day_index = days_of_week.index(current_day) + 1
# sorted_days = days_of_week.rotate(current_day_index)

# sorted_days.each do |day_of_the_week|
#   amount_of_timeslots_before = Timeslot.count

#   amount_of_timeslots_each_day.times do |i|
#     start_time = Date.today.next_occurring(day_of_the_week.to_sym).in_time_zone + i*timeslot_size.minutes
#     end_time = Date.today.next_occurring(day_of_the_week.to_sym).in_time_zone + i*timeslot_size.minutes + timeslot_size.minutes

#     Timeslot.create!(start_time: start_time, end_time: end_time, size: timeslot_size)
#   end

#   amount_of_timeslots_afterwards = Timeslot.count
#   amount_of_timeslots_created = amount_of_timeslots_afterwards - amount_of_timeslots_before
#   p "#{Date.today.next_occurring(day_of_the_week.to_sym).strftime("%A %d.%m")}: created #{amount_of_timeslots_created} timeslots"
# end


# seed_only_timeslots = true

# unless seed_only_timeslots == true
#   Timeslot.count.times do |i|
#     Event.create!(description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", title: "Event 1")
#   end
# end