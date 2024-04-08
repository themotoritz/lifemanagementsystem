class EventsController < ApplicationController
  require 'csv'
  include ApplicationHelper

  before_action :set_event, only: %i[ show edit update destroy ]

  # GET /events or /events.json
  def index 
    session[:current_view] = params[:current_view] if params[:current_view].present?
    session[:current_view] = "this_week" unless session[:current_view].present?
    
    case session[:current_view] || params[:current_view]
    when "today"
      days_of_week = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
      current_day = Date.today.strftime('%A').downcase
      current_day_index = days_of_week.index(current_day) + 1
      @sorted_days = days_of_week.rotate(current_day_index - 1)
      @events = Event.where("start_time <= ?", 1.week.from_now).order(:start_time)
    when "this_week", "this_month"
      @events = Event.where("start_time <= ?", 1.year.from_now).order(:start_time)
    when "this_year"
      @events = Event.where("kind != ? OR kind IS NULL", "blocking").order(:start_time)
    end

    @events
  end

  # GET /events/1 or /events/1.json
  def show
    if @event.group_id.present?
      @group_events = Event.where(group_id: @event.group_id)
      render 'show_group_events'
    else
      render 'show'
    end
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  def reschedule_past_events
    Event.where.not(kind: "blocking").where.not(done: true).where("start_time < ?", Time.now).all.each do |event|
      event = event
      
      event.start_time = nil
      event.end_time = nil

      event_scheduler = SingleEventScheduler.new(event)
      event = event_scheduler.schedule

      event.save  
    end
    
    redirect_to(events_path)
  end

  # POST /events or /events.json
  def create
    ActiveRecord::Base.transaction do
      date_param = params[:event][:date]
      time_param = params[:event][:time]

      @event = Event.new(event_params)
      @event.duration = event_params[:duration].to_i*60 if event_params[:duration].present?
      @event.recurrence = params[:event][:recurrence]

      if date_param.present? && time_param.present?
        time_zone = Time.zone
        datetime_str = "#{date_param} #{time_param}"
        datetime_with_zone = Time.zone.parse(datetime_str)
        @event.start_time = datetime_with_zone
        
        event_scheduler = SingleEventScheduler.new(@event)
        @event = event_scheduler.schedule
      elsif time_param.blank? && date_param.present?
        date = Date.parse(params[:event][:date])
        event_scheduler = SingleEventScheduler.new(@event)
        @event = event_scheduler.schedule_only_day(date)
      elsif date_param.blank? && time_param.blank?
        event_scheduler = SingleEventScheduler.new(@event)
        @event = event_scheduler.schedule
      else
        raise "unknown case"
        event_scheduler = SingleEventScheduler.new(@event)
        @event = event_scheduler.schedule
      end

      if @event.recurrence != "onetime"
        event_scheduler = MultipleEventScheduler.new(@event)
        events = event_scheduler.create_events(date_param, time_param)
      end

      respond_to do |format|
        if events.present?
            events.each do |event|
              raise ActiveRecord::Rollback unless event.save!
            end
          format.html { redirect_to events_url, notice: "Events were successfully created." }
          format.json { render :index, status: :created }
        else
          if @event.save
            format.html { redirect_to event_url(@event), notice: "Event was successfully created." }
            format.json { render :show, status: :created, location: @event }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @event.errors, status: :unprocessable_entity }
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  rescue ActiveRecord::Rollback
    format.html { render :new, status: :unprocessable_entity }
    format.json { render json: @event.errors, status: :unprocessable_entity }
    render :new
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    date = Date.parse(params[:event][:date])
    time = Time.parse(params[:event][:time]) if params[:event][:time].present?

    if date.present? && time.present?
      start_time = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)
      
      if @event.start_time.to_time.strftime("%Y-%m-%d %H:%M") != start_time.to_time.strftime("%Y-%m-%d %H:%M")
        @event.end_time = nil
        @event.start_time = start_time.to_time

        event_scheduler = SingleEventScheduler.new(@event)
        @event = event_scheduler.schedule
      end
    elsif time.nil? || time.empty?
      @event.end_time = nil
      event_scheduler = SingleEventScheduler.new(@event)
      @event = event_scheduler.schedule_only_day(date)
    else
    end


    @event.title = params[:event][:title]

    if @event.duration.to_s != params[:event][:duration]
      @event.end_time = nil
      @event.duration = params[:event][:duration].to_i

      event_scheduler = SingleEventScheduler.new(@event)
      @event = event_scheduler.schedule
    end

    @event.fixed = params[:event][:fixed]
    @event.done = params[:event][:done]
    @event.description = params[:event][:description]

    respond_to do |format|    
      if @event.save!
        format.html { redirect_to events_path, notice: "Event was successfully updated." }
        format.json { render :index , status: :ok, location: @event }
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
      format.csv { send_data @exported_records.export_to_csv, filename: "event-records-#{format_datetime(Time.now)}.csv" }
    end
  end

  def import_from_csv    
    file = params[:file]

    if file.present? && file.content_type == 'text/csv'
      ActiveRecord::Base.transaction do
        CSV.foreach(file.path, headers: true) do |row|
          @event = Event.new(row)

          # no need to schedule done tasks or birthdays which are in the past
          if @event.done == true || (@event.recurrence != "onetime" && @event.start_time.to_date < Date.today)
            raise ActiveRecord::Rollback unless @event.save!(validate: false)
          else
            date = @event.start_time.to_date
            @event.start_time = @event.end_time = nil
            event_scheduler = SingleEventScheduler.new(@event)
            @event = event_scheduler.schedule_only_day(date)
            raise ActiveRecord::Rollback unless @event.save!
          end
        end
      end
      flash[:success] = "Events imported successfully."
    else
      flash[:error] = "Please provide a CSV file."
    end

    redirect_to root_path
  rescue ActiveRecord::Rollback
    flash[:error] = "Validation failed. Events not imported."
    render :new
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:kind, :start_time, :duration, :fixed, :title, :end_time, :description, :done, :recurrence)
    end
end
