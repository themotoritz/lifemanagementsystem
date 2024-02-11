# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


timeslot_size = 15
length_of_day_in_minutes = 60*24
amount_of_timeslots_each_day = length_of_day_in_minutes / timeslot_size

["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"].each do |day_of_the_week|#
  amount_of_timeslots_each_day.times do |i|
    start_time = Date.today.next_week(day_of_the_week.to_sym).to_datetime + i*15.minutes
    end_time = Date.today.next_week(day_of_the_week.to_sym).to_datetime + i*15.minutes + 15.minutes
    
    Timeslot.create!(start_time: start_time, end_time: end_time, size: timeslot_size)
  end
end


500.times do |i|
  Event.create!
end