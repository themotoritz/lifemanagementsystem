class EventsController < ApplicationController
  require 'csv'
  
  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events or /events.json
  def index 
    session[:current_view] = params[:current_view] if params[:current_view].present?
    session[:current_view] = "this_week" unless session[:current_view].present?

    @events = Event.where.not(kind: "blocking").order(:start_time)
  end

  # GET /events/1 or /events/1.json
  def show
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  def reschedule_past_events
    Event.where.not(kind: "blocking").where("start_time < ?", Time.now).all.each do |event|
      event.start_time = nil
      event.end_time = nil
      event.save  
    end
    
    redirect_to(events_path)
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)
    @event.duration = event_params[:duration].to_i*60 if event_params[:duration].present?

    schedule_event

    respond_to do |format|
      if @event.save
        format.html { redirect_to event_url(@event), notice: "Event was successfully created." }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_to do |format|
      @event.assign_attributes(event_params)
      if @event.save(validate: false)
        format.html { redirect_to event_url(@event), notice: "Event was successfully updated." }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def export_to_csv
    @exported_records = Event.where.not(kind: "blocking") # Adjust the condition as needed
    respond_to do |format|
      format.csv { send_data @exported_records.export_to_csv, filename: "event-records-#{Date.today}.csv" }
    end
  end

  def import_from_csv    
    file = params[:file]

    if file.present? && file.content_type == 'text/csv'
      CSV.foreach(file.path, headers: true) do |row|
        event = Event.new(row)
        event.end_time = nil
        if event.start_time.present? && event.start_time < Time.now + 5.minutes
          event.start_time = nil
        end   
        event.save!
      end
      flash[:success] = "Records imported successfully."
    else
      flash[:error] = "Please provide a CSV file."
    end

    redirect_to root_path
  end

  def schedule_event
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
      @event.start_time = timeslot.start_time if timeslot.present?
    end

    @event.end_time = @event.start_time + @event.duration if @event.start_time.present? && @event.duration.present?

    udpate_timeslots(timeslot) if timeslot.present?
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:kind, :start_time, :duration, :fixed, :title, :end_time, :description, :done)
    end
end
