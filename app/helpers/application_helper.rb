module ApplicationHelper
  def format_seconds_to_time(seconds)
    return unless seconds.present?
    
    if seconds < 60
      "#{seconds} Seconds"
    elsif seconds < 3600
      minutes = seconds / 60
      "#{minutes} Minute#{'s' if minutes != 1}"
    else
      hours = seconds / 3600
      remaining_minutes = (seconds % 3600) / 60
      "#{hours} hour#{'s' if hours != 1} #{remaining_minutes} minute#{'s' if remaining_minutes != 1}"
    end
  end

  def format_datetime(datetime, include_date = true)
    return unless datetime.present?

    if datetime.is_a?(String)
      datetime = DateTime.parse(datetime)
    else
      datetime = datetime
    end

    if include_date == true
      datetime.strftime("%Y-%m-%d %H:%M")
    elsif include_date == false
      datetime.strftime("%H:%M")
    end
  end

  def fallback_value(object, attribute, fallback = "-")
    object_attribute = object.send(attribute)
    object_attribute.presence || fallback
  end

  def today_css_background_color_for(event)
    if event.priority >= 90
      "bg-red-500"
    else
      ""
    end
  end

  def this_week_css_background_color_for(event)
    if event.priority >= 90
      "bg-red-500"
    else
      "bg-sky-300"
    end
  end

  def this_month_css_background_color_for(event)
    if event.priority >= 90
      "bg-red-500"
    else
      "bg-sky-300"
    end
  end

  def this_year_css_background_color_for(event)
    if event.priority >= 90
      "bg-red-500"
    else
      ""
    end
  end

  def convert_seconds_to_minutes(seconds)
    seconds / 60 if seconds.present?
  end
end
