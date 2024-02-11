json.extract! event, :id, :type, :start_time, :duration, :fixed, :created_at, :updated_at
json.url event_url(event, format: :json)
