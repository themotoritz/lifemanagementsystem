class EventsController < ApplicationController
  require 'csv'
  include ApplicationHelper

  before_action :set_event, only: %i[ show edit update destroy ]
  before_action :convert_duration_to_seconds, only: %i[ create update ]
  before_action :get_project_names, only: %i[ new edit ]
  before_action :archive_done_events, only: %i[ reschedule_events reschedule_past_events ]

  def done_events
    @done_events = Event.done.order(done_at: :desc)
  end

  def archive_done_events
    ActiveRecord::Base.transaction do
      events_to_archive = Event.future.done

      events_to_archive.each do |event|
        event.start_time = event.end_time = event.duration = nil
        event.archived = true
        event.save
      end
    end
  end

  # GET /events or /events.json
  def index
    session[:current_view] = params[:current_view] if params[:current_view].present?
    session[:current_view] = "this_week" unless session[:current_view].present?

    @done_events = Event.done
    @undone_events = Event.undone
    date_today = Date.today

    case session[:current_view] || params[:current_view]
    when "today"
      days_of_week = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
      current_day = date_today.strftime('%A').downcase
      current_day_index = days_of_week.index(current_day) + 1
      @sorted_days = days_of_week.rotate(current_day_index - 1)
      @undone_events_not_blocking_count = @undone_events.not_blocking.future.count
      @done_events_count = @done_events.count
      @events = @undone_events.where("start_time <= ?", 1.week.from_now).order(:start_time)
      @events_hash = {}
      @events_hash = @events.where(start_time: date_today.beginning_of_day..(date_today+7.days).end_of_day).group_by { |event| event.start_time.strftime("%A").downcase }
    when "this_week", "this_month"
      @events = @undone_events.where("start_time <= ?", 1.year.from_now).order(:start_time)
    when "this_year"
      @events = @undone_events.not_blocking.order(:start_time)
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
      order_mapping = {
        "duration": :asc,
        "priority": :desc,
        "motivation_level": :desc
      }

      events = Event.future.undone.recurrence_onetime.not_blocking.not_fixed
      
      if attribute == :priority || attribute == :duration || attribute == :motivation_level
        events_to_destroy = events_to_reschedule = events

        if params[:project].present? && params[:project] != "none"
          events_to_reschedule = events_to_reschedule.where(project: params[:project]).order("#{attribute}": order_mapping[attribute]) + events_to_reschedule.where("project != ? OR project IS NULL", params[:project]).order("#{attribute}": :desc)
        else
          events_to_reschedule = events_to_reschedule.order("#{attribute}": order_mapping[attribute])
        end
      
        events = EventScheduler.new(events_to_reschedule).call
      end
    end

    redirect_to(events_path)
  end

  def reschedule_past_events
    ActiveRecord::Base.transaction do
      events = Event.undone.past.not_blocking.not_fixed.where.not(recurrence: "yearly").order(priority: :desc).all
      events = EventScheduler.new(events).call
    end

    redirect_to(events_path)
  end

  def prepare_date_and_time
    starts_at_date = event_params[:starts_at_date]
    starts_at_hour = event_params[:starts_at_hour]
    starts_at_minute = event_params[:starts_at_minute]

    if starts_at_date.blank? && starts_at_hour.blank? && starts_at_minute.blank?
      "do nothing"
    elsif starts_at_date.present? && starts_at_hour.blank? && starts_at_minute.blank?
      @event.fixed_date = true
      @event.fixed_date_at = @event.start_time.to_date
    elsif starts_at_date.present? && starts_at_hour.present? && starts_at_minute.present?
      @event.fixed_time = true
      @event.fixed_datetime_at = @event.start_time
    else
      # TODO: add error message to view for now. Implement those "special" cases later
    end
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)
    prepare_date_and_time

    ActiveRecord::Base.transaction do
      date_param = params[:event][:date]
      time_param = params[:event][:time]

      if date_param.present? && time_param.present? && Time.zone.parse("#{date_param} #{time_param}") < Time.current
        flash[:error] = "Date cannot be in the past"
        redirect_to new_event_path
        return
      end

      
      @event.duration = event_params[:duration].to_i if event_params[:duration].present?
      @event.duration ||= 900
      @event.recurrence = params[:event][:recurrence]     
      @event = EventScheduler.new(@event).call

      if @event.recurrence != "onetime"
        @event.fixed_date = true
        event_scheduler = MultipleEventScheduler.new(@event)
        events = event_scheduler.create_events(date_param, time_param)
      end

      respond_to do |format|
        if events.present?
            events.each do |event|
              raise ActiveRecord::Rollback unless event.save!
            end
          format.html do 
            flash[:success] = "Events were successfully created."
            redirect_to events_url
          end
          format.json { render :index, status: :created }
        else
          if @event.save
            format.html do
              flash[:success] = "Event was successfully created."
              redirect_to events_url
            end
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
    # params:
    # <ActionController::Parameters {"_method"=>"patch", "authenticity_token"=>"GbC23oW9TO2n45ifzJw0yi1Z1oqNk337Idb0OiFY5IzQzmX4aDXE4KPg_hmwfw21a9OU3jpehAlcHBsWoWRj1w", "event"=>#<ActionController::Parameters {"title"=>"Einkaufen", "kind"=>"", "project"=>"", "description"=>"1. neue kleine Pfanne\n2. neue sportklamotten (whörl mit Gutschein)\n3. Sommerschuhe\n4. neue Holzfällerhemden (z.B. schwarz-weiß, Kompliment von Heiko bekommen)\n5. Brillenputzmittel\n6. Küchentücher", "date"=>"2024-05-27", "time"=>"22:15", "end_time"=>"2024-05-27T22:30", "priority"=>"45", "fixed"=>"0", "done"=>"0"/"1", "duration"=>"900"} permitted: false>, "commit"=>"Eintrag aktualisieren", "controller"=>"events", "action"=>"update", "id"=>"9855"} permitted: false>
    ActiveRecord::Base.transaction do
      changes = get_changes

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

          event_class_array = EventScheduler.new(@event).call
          @event = event_class_array.first
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
      @event.fixed_date = params[:event][:fixed_date]
      @event.done = params[:event][:done]
      @event.description = params[:event][:description]
      @event.title = params[:event][:title]
      @event.project = params[:event][:project]
      @event.done_at = Time.current if params[:event][:done] == "1"
      @event.upload = params[:event][:upload]
      @event.result = params[:event][:result]
      @event.motivation_level = params[:event][:motivation_level]
      @event.lack_of_motivation_reason = params[:event][:lack_of_motivation_reason]

      respond_to do |format|
        if @event.save!
          format.html do
            flash[:success] = "Event was successfully updated."
            redirect_to events_path
          end
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

  def mark_as_done
    event = Event.find(params[:id])
    current_time = Time.current
    event.update_columns(done: true, done_at: current_time, updated_at: current_time)
    flash[:success] = "Event marked as done."
    redirect_to events_path
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html do 
        flash[:success] = "Event was successfully destroyed."
        redirect_to events_url
      end
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
        CSV.foreach(file.path, headers: true).with_index do |row, index|
          @event = Event.new(row)

          # no need to schedule done tasks or birthdays which are in the past
          if @event.done == true || (@event.recurrence != "onetime" && @event.start_time.to_date < Date.today)
            raise ActiveRecord::Rollback unless @event.save!(validate: false)
          else
            date = @event.start_time.to_date
            @event.start_time = @event.end_time = nil
            event_scheduler = SingleEventScheduler.new(@event)
            if index == 0
              @event = event_scheduler.schedule_only_day(date, destroy_past_timeslots: true, first_record: true)
            else
              @event = event_scheduler.schedule_only_day(date)
            end
            
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
      params.require(:event).permit(:kind, :start_time, :duration_in_minutes, :duration, :fixed, :title, :end_time, :description, :done, :recurrence, :priority, :project, :fixed_date, :upload, :result, :motivation_level, :lack_of_motivation_reason, :starts_at_date, :starts_at_hour, :starts_at_minute, :ends_at_date, :ends_at_hour, :ends_at_minute)
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

        if key == "duration" || key == "priority" || key == "motivation_level"
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
      @project_names = Event.project_names.unshift("none")
    end
end