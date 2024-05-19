class EventsController < ApplicationController
  require 'csv'
  include ApplicationHelper

  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :convert_duration_to_seconds, only: %i[ create update ]
  before_action :get_project_names, only: %i[ new edit ]

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
      @events = Event.not_blocking.order(:start_time)
    end

    @events
  end

  # GET /events/1 or /events/1.json
  def show
    if @event.group_id.present?
      @group_events = Event.where(group_id: @event.group_id).order(start_time: :asc)
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

  def reschedule_events
    ActiveRecord::Base.transaction do
      attribute = params[:sort_by].to_sym

      if attribute == :priority
        events_to_destroy = Event.undone.recurrence_onetime.not_blocking.order(start_time: :desc)
        
        events_to_reschedule = Event.undone.recurrence_onetime.not_blocking
        
        if params[:project].present? && params[:project] != "none"
          events_to_reschedule = events_to_reschedule.where(project: params[:project]).order("#{attribute}": :desc) + events_to_reschedule.where("project != ? OR project IS NULL", params[:project]).order("#{attribute}": :desc) 
        else
          events_to_reschedule = events_to_reschedule.order("#{attribute}": :desc)
        end

        new_events = []
        events_to_reschedule.each do |event|
          new_events << event.dup
        end

        events_to_destroy.each do |event|
          #Timeslot.update_bordering_timeslots_before_destroying(event)
          event.destroy
        end
        
        new_events.each do |event|
          recreated_event = event
          recreated_event.start_time = recreated_event.end_time = nil

          event_scheduler = SingleEventScheduler.new(recreated_event)
          recreated_event = event_scheduler.schedule

          recreated_event.save!
        end
      elsif attribute == :duration
        events_to_destroy = Event.undone.recurrence_onetime.not_blocking.order(start_time: :desc)
        
        events_to_reschedule = Event.undone.recurrence_onetime.not_blocking
        
        if params[:project].present? && params[:project] != "none"
          events_to_reschedule = events_to_reschedule.where(project: params[:project]).order("#{attribute}": :desc) + events_to_reschedule.where("project != ? OR project IS NULL", params[:project]).order("#{attribute}": :desc) 
        else
          events_to_reschedule = events_to_reschedule.order("#{attribute}": :desc)
        end

        new_events = []
        events_to_reschedule.each do |event|
          new_events << event.dup
        end

        events_to_destroy.each do |event|
          #Timeslot.update_bordering_timeslots_before_destroying(event)
          event.destroy
        end
        
        new_events.each do |event|
          recreated_event = event
          recreated_event.start_time = recreated_event.end_time = nil

          event_scheduler = SingleEventScheduler.new(recreated_event)
          recreated_event = event_scheduler.schedule

          recreated_event.save!
        end
      end
    end
    
    redirect_to(events_path)
  end

  def reschedule_past_events
    ActiveRecord::Base.transaction do
      Event.undone.past.not_blocking.where.not(recurrence: "yearly").order(priority: :desc).all.each do |event|
        Timeslot.update_bordering_timeslots_before_destroying(event)
        event.start_time = event.end_time = nil

        event_scheduler = SingleEventScheduler.new(event)
        event = event_scheduler.schedule

        event.save  
      end
    end
    
    redirect_to(events_path)
  end

  # POST /events or /events.json
  def create
    ActiveRecord::Base.transaction do
      date_param = params[:event][:date]
      time_param = params[:event][:time]

      if date_param.present? && time_param.present? && Time.zone.parse("#{date_param} #{time_param}") < Time.current
        flash[:error] = "Date cannot be in the past"
        redirect_to new_event_path
        return
      end

      @event = Event.new(event_params)
      @event.duration = event_params[:duration].to_i if event_params[:duration].present?
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
            flash[:error] = @event.errors.full_messages.join(", ")
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @event.errors, status: :unprocessable_entity }
            raise ActiveRecord::Rollback
          end
        end
      end
    end
  rescue ActiveRecord::Rollback
    flash[:error] = @event.errors.full_messages.join(", ")
    format.html { render :new, status: :unprocessable_entity }
    format.json { render json: @event.errors, status: :unprocessable_entity }
    render :new
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    ActiveRecord::Base.transaction do
      changes = get_changes

      Timeslot.update_bordering_timeslots_before_destroying(@event)

      if changes.key?("start_time") || changes.key?("end_time") || changes.key?("duration")
        date = Date.parse(params[:event][:date]) if params[:event][:date].present?
        time = Time.parse(params[:event][:time]) if params[:event][:time].present?

        if date.present? && time.present?
          start_time = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec)
          
          if @event.start_time.to_time.strftime("%Y-%m-%d %H:%M") != start_time.to_time.strftime("%Y-%m-%d %H:%M")
            @event.end_time = nil
            @event.start_time = start_time.to_time

            event_scheduler = SingleEventScheduler.new(@event)
            @event = event_scheduler.schedule
          end
        elsif date.blank? && time.blank?
          @event.end_time = @event.start_time = nil

          event_scheduler = SingleEventScheduler.new(@event)
          @event = event_scheduler.schedule
        elsif date.present? && time.blank?
          @event.end_time = @event.start_time = nil
          
          event_scheduler = SingleEventScheduler.new(@event)
          @event = event_scheduler.schedule_only_day(date)
        else
        end

        if @event.duration.to_s != params[:event][:duration]
          @event.end_time = nil
          @event.duration = params[:event][:duration].to_i

          event_scheduler = SingleEventScheduler.new(@event)
          @event = event_scheduler.schedule
        end
      end

      @event.priority = params[:event][:priority]
      @event.fixed = params[:event][:fixed]
      @event.done = params[:event][:done]
      @event.description = params[:event][:description]
      @event.title = params[:event][:title]
      @event.project = params[:event][:project]

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
  rescue ActiveRecord::Rollback
    format.html { render :edit, status: :unprocessable_entity }
    format.json { render json: @event.errors, status: :unprocessable_entity }
    render :edit
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    Timeslot.update_bordering_timeslots_before_destroying(@event)
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def export_to_csv
    @exported_records = Event.not_blocking
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
      params.require(:event).permit(:kind, :start_time, :duration_in_minutes, :duration, :fixed, :title, :end_time, :description, :done, :recurrence, :priority, :project)
    end

    def get_changes
      changes = {}

      params[:event].each do |key, value|
        if key == "end_time" || key == "start_time"
          value = value.in_time_zone(Time.zone)
        end

        if key == "date"
          value = value.in_time_zone(Time.zone)
          key = "start_time"
        end

        if key == "duration" || key == "priority"
          value = value.to_i
        end

        if value.present? && @event.respond_to?(key) && @event.attributes[key.to_s] != value
          if key == "done" || key == "fixed"
            if value == "0" && @event.attributes[key.to_s] == false
              next
            elsif value == "1" && @event.attributes[key.to_s] == true
              next
            end
          end

          changes[key] = {
            old_value: @event.attributes[key.to_s],
            new_value: value
          }
        end
      end
      
      changes
    end

    def convert_duration_to_seconds
      if params[:event][:duration_in_minutes].present?
        params[:event][:duration] = (params[:event][:duration_in_minutes].to_i*60).to_s
      end
      params[:event].delete("duration_in_minutes")
    end

    def get_project_names
      @project_names = Event.pluck(:project).uniq.compact.join(", ")
    end
end
