class Calendar
  attr_accessor :events

  def initialize
    @events = Event.future.undone.order(:start_time).to_a
  end

  def call
  end
end