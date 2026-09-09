class SponsorPassportsController < ApplicationController
  include ApplicationHelper

  before_action :require_logged_in

  def show
    event = Event.find_by!(slug: params[:event_slug])
    raise ActiveRecord::RecordNotFound unless event == current_event

    @passport = SponsorPassport.new(event:, user: current_user!)
  end
end
