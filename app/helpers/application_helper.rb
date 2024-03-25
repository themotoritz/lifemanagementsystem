module ApplicationHelper
  def format_seconds_to_time(seconds)
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
    if datetime.is_a?(String)
      datetime = DateTime.parse(datetime)
    else
      datetime = datetime
    end

    if include_date == true
      datetime.strftime("%Y-%m-%d %H:%M")
    elsif include_date == false
      datetime.strftime("%H:%M:%S")
    end
  end

  def fallback_value(object, attribute, fallback = "-")
    object_attribute = object.send(attribute)
    object_attribute.presence || fallback
  end
end
