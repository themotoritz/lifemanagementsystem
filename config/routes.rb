Rails.application.routes.draw do
  resources :events
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get 'reschedule_past_events', action: :reschedule_past_events, controller: 'events'
  get 'reschedule_events', action: :reschedule_events, controller: 'events'
  get 'export_events_to_csv', action: :export_to_csv, controller: 'events'
  get 'done_events', action: :done_events, controller: 'events'
  post 'import_events_from_csv', action: :import_from_csv, controller: 'events'
  patch 'mark_as_done/:id', to: 'events#mark_as_done', as: :mark_as_done

  root "events#index"
end