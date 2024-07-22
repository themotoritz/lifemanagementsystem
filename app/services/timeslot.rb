class Timeslot
  attr_accessor :start_time, :end_time, :size

  def initialize(start_time:, end_time:, size:)
    @start_time = start_time
    @end_time = end_time
    @size = size
  end
end