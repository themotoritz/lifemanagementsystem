class ApplicationController < ActionController::Base
  before_action :load_variables

  private

  def load_variables
    @project_names = Event.project_names.unshift("none")
  end
end